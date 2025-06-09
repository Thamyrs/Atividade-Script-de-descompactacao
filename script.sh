#!/bin/bash

mensagem_inicial() {
    echo "Oi meu chapa. Bem-vindo ao compactador de arquivos."
    sleep 0.5
    echo "Carregando..."
    sleep 2
    clear
}

coleta_nome_usuario() {
    while true; do
        echo "Digite o nome do usuário que está realizando o backup:"
        read -r nome
        
        nome_sem_espacos=$(echo "$nome" | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [[ -z "$nome_sem_espacos" ]]; then
            echo "O nome não pode estar em branco ou conter apenas espaços. Tente novamente."
        else
            nome_usuario="$nome_sem_espacos"
            break
        fi
    done
    clear
}

valida_diretorio() {
    local diretorio="$1"
    [[ -d "$diretorio" ]]
}

coleta_diretorio_origem() {
    while true; do
        echo "Digite o caminho completo do diretório de origem:"
        read -r diretorio_origem

        if valida_diretorio "$diretorio_origem"; then
            break
        else
            echo "Diretório não encontrado. Tente novamente."
        fi
    done
    clear
}

lista_arquivos_compactados() {
    echo "Arquivos compactados disponíveis em $diretorio_origem:"
    find "$diretorio_origem" -maxdepth 1 -type \( -iname "*.tar" -o -iname "*.gz" -o -iname "*.bz2" \) -printf "%f\n" | nl
}

valida_arquivo_origem() {
    local arquivo="$1"
    [[ -f "$diretorio_origem/$arquivo" ]] && [[ "$arquivo" =~ \.(tar|gz|bz2)$ ]]
}

seleciona_arquivo_origem() {
    while true; do
        lista_arquivos_compactados
        
        echo "Digite o número ou nome do arquivo que deseja descompactar:"
        read -r entrada_usuario

        if [[ "$entrada_usuario" =~ ^[0-9]+$ ]]; then
            arquivo_escolhido=$(find "$diretorio_origem" -maxdepth 1 -type f \( -iname "*.tar" -o -iname "*.gz" -o -iname "*.bz2" \) -printf "%f\n" | sed -n "${entrada_usuario}p")
            
            if [[ -z "$arquivo_escolhido" ]]; then
                echo "Número inválido. Tente novamente."
                continue
            fi
        else
            arquivo_escolhido="$entrada_usuario"
        fi

        if valida_arquivo_origem "$arquivo_escolhido"; then
            nome_arquivo_origem="$arquivo_escolhido"
            break
        else
            echo "Arquivo inválido ou não encontrado. Certifique-se que é .tar, .gz ou .bz2."
        fi
    done
    clear
}

coleta_diretorio_destino() {
    while true; do
        echo "Digite o diretório de destino para descompactação:"
        read -r diretorio_destino

        if valida_diretorio "$diretorio_destino"; then
            break
        else
            echo "Diretório não existe. Deseja criar? (s/n)"
            read -r opcao
            if [[ "$opcao" =~ ^[Ss]$ ]]; then
                mkdir -p "$diretorio_destino" && break
                echo "Falha ao criar diretório. Tente novamente."
            fi
        fi
    done
    clear
}

coleta_nome_saida() {
    while true; do
        echo "Digite um nome para a pasta de saída (sem extensão):"
        read -r nome_saida
        
        nome_saida=$(echo "$nome_saida" | sed 's/^[ \t]*//;s/[ \t]*$//')

        if [[ -z "$nome_saida" ]]; then
            echo "O nome não pode estar em branco. Tente novamente."
        else

            nome_saida=$(echo "$nome_saida" | tr -d '/\\')
            break
        fi
    done
    clear
}

descompacta_arquivo() {
    local caminho_origem="$diretorio_origem/$nome_arquivo_origem"
    local caminho_destino="$diretorio_destino/$nome_saida"
    
    echo "Preparando para descompactar $nome_arquivo_origem..."
    sleep 1

    mkdir -p "$caminho_destino"

    case "$nome_arquivo_origem" in
        *.tar)
            echo "Descompactando arquivo TAR..."
            tar -xvf "$caminho_origem" -C "$caminho_destino"
            ;;
        *.gz)
            echo "Descompactando arquivo GZIP..."
            tar -xzvf "$caminho_origem" -C "$caminho_destino"
            ;;
        *.bz2)
            echo "Descompactando arquivo BZIP2..."
            tar -xjvf "$caminho_origem" -C "$caminho_destino"
            ;;
        *)
            echo "Formato não suportado!"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Descompactação concluída em: $caminho_destino"
        return 0
    else
        echo "Erro na descompactação!"
        return 1
    fi
}

gera_log() {
    local log_file="$diretorio_destino/log_descompactacao.txt"
    local tamanho=$(du -sh "$diretorio_origem/$nome_arquivo_origem" | cut -f1)
    
    echo "=== LOG DE DESCOMPACTAÇÃO ===" > "$log_file"
    echo "Data/Hora: $(date +%d-%m-%Y_%H:%M:%S)" >> "$log_file"
    echo "Usuário: $nome_usuario" >> "$log_file"
    echo "Arquivo original: $nome_arquivo_origem ($tamanho)" >> "$log_file"
    echo "Diretório destino: $diretorio_destino/$nome_saida" >> "$log_file"
    
    echo "Log gerado em: $log_file"
    sleep 2
    clear
}

main() {
    mensagem_inicial
    coleta_nome_usuario
    coleta_diretorio_origem
    seleciona_arquivo_origem
    coleta_diretorio_destino
    coleta_nome_saida
    
    if descompacta_arquivo; then
        gera_log
    else
        echo "Operação falhou. Verifique os dados e tente novamente."
    fi
    
    echo "Processo concluído!"
}

main
