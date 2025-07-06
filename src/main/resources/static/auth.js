/**
 * Sistema de Autenticação - auth.js
 * Gerencia login, logout e verificação de sessão
 */

class AuthSystem {
    constructor() {
        this.TEMPO_SESSAO = 8 * 60 * 60 * 1000; // 8 horas
        this.CHAVE_SESSAO = 'sessaoTarefas';
    }

    // Verificar se o usuário está logado
    verificarAutenticacao() {
        const sessao = this.obterSessao();
        if (!sessao) {
            this.redirecionarParaLogin();
            return false;
        }
        return true;
    }

    // Obter dados da sessão
    obterSessao() {
        try {
            const sessaoStr = localStorage.getItem(this.CHAVE_SESSAO);
            if (!sessaoStr) return null;
            
            const sessao = JSON.parse(sessaoStr);
            const agora = new Date().getTime();
            
            // Verificar se a sessão ainda é válida
            if (agora < sessao.expirationTime) {
                return sessao;
            } else {
                // Sessão expirou
                this.logout();
                return null;
            }
        } catch (error) {
            console.error('Erro ao obter sessão:', error);
            this.logout();
            return null;
        }
    }

    // Fazer logout
    logout() {
        localStorage.removeItem(this.CHAVE_SESSAO);
        this.redirecionarParaLogin();
    }

    // Redirecionar para login
    redirecionarParaLogin() {
        if (!window.location.pathname.includes('login.html')) {
            window.location.href = 'login.html';
        }
    }

    // Obter nome do usuário logado
    obterUsuarioLogado() {
        const sessao = this.obterSessao();
        return sessao ? sessao.usuario : null;
    }

    // Verificar se sessão expira em breve (últimos 30 minutos)
    sessaoExpirandoEm() {
        const sessao = this.obterSessao();
        if (!sessao) return 0;
        
        const agora = new Date().getTime();
        const tempoRestante = sessao.expirationTime - agora;
        return Math.max(0, tempoRestante);
    }

    // Renovar sessão (estender por mais 8 horas)
    renovarSessao() {
        const sessao = this.obterSessao();
        if (sessao) {
            const agora = new Date().getTime();
            sessao.expirationTime = agora + this.TEMPO_SESSAO;
            localStorage.setItem(this.CHAVE_SESSAO, JSON.stringify(sessao));
            return true;
        }
        return false;
    }
}

// Instância global do sistema de autenticação
const auth = new AuthSystem();

// Função para inicializar verificação de autenticação em páginas protegidas
function inicializarAutenticacao() {
    // Verificar se está na página de login
    if (window.location.pathname.includes('login.html')) {
        return; // Não verificar autenticação na página de login
    }

    // Verificar autenticação
    if (!auth.verificarAutenticacao()) {
        return;
    }

    // Adicionar informações do usuário na navbar se existir
    adicionarInfoUsuarioNavbar();

    // Configurar aviso de sessão expirando
    configurarAvisoSessao();

    // Renovar sessão a cada atividade do usuário
    configurarRenovacaoAutomatica();
}

// Adicionar informações do usuário na navbar
function adicionarInfoUsuarioNavbar() {
    const navbar = document.querySelector('.navbar .container');
    if (navbar) {
        const usuario = auth.obterUsuarioLogado();
        const userInfo = document.createElement('div');
        userInfo.className = 'navbar-nav ms-auto d-flex flex-row align-items-center';
        userInfo.innerHTML = `
            <span class="navbar-text me-3">
                <i class="fas fa-user me-1"></i>
                Olá, <strong>${usuario}</strong>
            </span>
            <button class="btn btn-outline-light btn-sm" onclick="confirmarLogout()" title="Sair do sistema">
                <i class="fas fa-sign-out-alt"></i>
            </button>
        `;
        navbar.appendChild(userInfo);
    }
}

// Configurar aviso quando a sessão estiver expirando
function configurarAvisoSessao() {
    setInterval(() => {
        const tempoRestante = auth.sessaoExpirandoEm();
        const trintaMinutos = 30 * 60 * 1000; // 30 minutos em ms
        
        if (tempoRestante > 0 && tempoRestante <= trintaMinutos) {
            const minutosRestantes = Math.ceil(tempoRestante / (60 * 1000));
            
            if (minutosRestantes <= 5) {
                mostrarAvisoSessao(minutosRestantes);
            }
        }
    }, 60000); // Verificar a cada minuto
}

// Mostrar aviso de sessão expirando
function mostrarAvisoSessao(minutosRestantes) {
    const existeAviso = document.getElementById('avisoSessao');
    if (existeAviso) return; // Não duplicar avisos

    const aviso = document.createElement('div');
    aviso.id = 'avisoSessao';
    aviso.className = 'alert alert-warning alert-dismissible fade show position-fixed';
    aviso.style.cssText = 'top: 20px; right: 20px; z-index: 9999; max-width: 350px;';
    aviso.innerHTML = `
        <i class="fas fa-clock me-2"></i>
        <strong>Sessão expirando!</strong><br>
        Sua sessão expirará em ${minutosRestantes} minuto${minutosRestantes > 1 ? 's' : ''}.
        <button type="button" class="btn btn-sm btn-outline-warning ms-2" onclick="renovarSessaoUsuario()">
            Renovar
        </button>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(aviso);
    
    // Remover automaticamente após 10 segundos
    setTimeout(() => {
        if (aviso.parentNode) {
            aviso.remove();
        }
    }, 10000);
}

// Renovar sessão do usuário
function renovarSessaoUsuario() {
    if (auth.renovarSessao()) {
        // Remover aviso se existir
        const aviso = document.getElementById('avisoSessao');
        if (aviso) {
            aviso.remove();
        }
        
        // Mostrar confirmação
        if (typeof mostrarAlerta === 'function') {
            mostrarAlerta('success', 'Sessão renovada com sucesso!');
        }
    }
}

// Configurar renovação automática da sessão
function configurarRenovacaoAutomatica() {
    // Eventos que indicam atividade do usuário
    const eventos = ['click', 'keypress', 'scroll', 'mousemove'];
    let ultimaAtividade = new Date().getTime();
    
    eventos.forEach(evento => {
        document.addEventListener(evento, () => {
            const agora = new Date().getTime();
            // Se passou mais de 5 minutos desde a última renovação
            if (agora - ultimaAtividade > 5 * 60 * 1000) {
                auth.renovarSessao();
                ultimaAtividade = agora;
            }
        });
    });
}

// Confirmar logout
function confirmarLogout() {
    if (confirm('Tem certeza que deseja sair do sistema?')) {
        auth.logout();
    }
}

// Inicializar automaticamente quando a página carregar
document.addEventListener('DOMContentLoaded', inicializarAutenticacao);