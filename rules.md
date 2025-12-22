# 🤖 RULES CLAUDE CODE - Protocolo de Desenvolvimento SaaS

> **IMPORTANTE**: Este arquivo define regras obrigatórias para o Claude Code seguir durante o desenvolvimento. Mantenha-o na raiz do projeto.

---

## 🎯 OBJETIVO DESTE ARQUIVO

Garantir que o Claude Code (IA da Anthropic no VSCode) desenvolva seu SaaS com:
- ✅ **Segurança**: Não quebrar código funcionando
- ✅ **Observabilidade**: Você entender cada mudança
- ✅ **Qualidade**: Código organizado e testável
- ✅ **Aprendizado**: Explicações claras para iniciantes

---

## 🚫 REGRA #1: NUNCA CODIFICAR SEM PLANEJAR

**OBRIGATÓRIO**: Antes de qualquer implementação, o Claude Code DEVE:

### 1. Criar arquivo de planejamento: `PLAN_[feature-name].md`

```markdown
# PLANEJAMENTO: [Nome da Feature]

## 📝 O que vai ser feito:
[Explicação simples em português]

## 🎯 Por que isso é necessário:
[Justificativa clara]

## 📂 Arquivos que serão modificados:
- [ ] `caminho/arquivo1.js` - [O que vai mudar]
- [ ] `caminho/arquivo2.js` - [O que vai mudar]
- [ ] (novo) `caminho/arquivo3.js` - [Por que será criado]

## 📦 Dependências necessárias:
- [ ] Biblioteca X - [Para que serve]
- [ ] Serviço Y - [Como será usado]

## ⚠️ RISCOS IDENTIFICADOS:
- **Risco 1**: [Descrição] → [Como evitar]
- **Risco 2**: [Descrição] → [Como evitar]

## 🔗 O que depende deste código:
[Listar componentes/funcionalidades que podem ser afetados]

## 📋 PASSOS DE IMPLEMENTAÇÃO:

### Fase 1: Preparação
1. [ ] [Passo específico]
2. [ ] [Passo específico]

### Fase 2: Implementação Core
3. [ ] [Passo específico]
4. [ ] [Passo específico]

### Fase 3: Testes e Validação
5. [ ] [Passo específico]
6. [ ] [Passo específico]

## ✅ Como validar que funcionou:
1. [Teste manual específico]
2. [Comportamento esperado]
3. [Como reverter se der errado]

## 🤔 AGUARDANDO APROVAÇÃO
- [ ] Li e entendi o plano
- [ ] Concordo com a abordagem
- [ ] Pode prosseguir

**Status**: ⏸️ AGUARDANDO APROVAÇÃO DO DESENVOLVEDOR
```

### 2. AGUARDAR APROVAÇÃO EXPLÍCITA

❌ **NUNCA comece a codificar sem o desenvolvedor dizer "pode prosseguir"**

---

## 🛡️ REGRA #2: PROTEÇÃO DE CÓDIGO EXISTENTE

### Antes de modificar QUALQUER arquivo:

```markdown
## 🔍 ANÁLISE DE IMPACTO: [nome-do-arquivo]

### O que existe atualmente:
[Breve descrição da funcionalidade atual]

### O que será modificado:
[Descrever as mudanças linha por linha se necessário]

### Quem usa este código:
- [Componente A] usa a função X
- [Componente B] depende da variável Y

### Possíveis quebras:
- ⚠️ [Cenário que pode quebrar]
- ⚠️ [Outro cenário de risco]

### Como proteger:
- ✅ [Estratégia de segurança 1]
- ✅ [Estratégia de segurança 2]
```

### Sistema de Comentários OBRIGATÓRIO:

Sempre adicionar antes de código complexo:

```javascript
// 🤖 CLAUDE-NOTE: [Explicação do que este código faz e POR QUE existe]
// 📅 Criado em: [data]
// 🎯 Propósito: [Para que serve]
// ⚠️ IMPORTANTE: [Cuidados ao modificar]
// 🔗 Usado por: [Onde este código é usado]

// Seu código aqui...
```

Para código existente que será MODIFICADO:

```javascript
// 🔄 CLAUDE-MODIFIED: [Data] - [O que foi mudado e por quê]
// 📌 Original: [Breve descrição do comportamento anterior]
// ✨ Novo: [Descrição do novo comportamento]
// ⚠️ Impacto: [O que pode ser afetado]
```

Para marcar problemas:

```javascript
// 🚨 CLAUDE-WARNING: [Descrição do problema ou limitação]
// 💡 TODO: [O que precisa ser melhorado]
// ❓ CLAUDE-QUESTION: [Dúvida que precisa de decisão humana]
```

---

## 📊 REGRA #3: OBSERVABILIDADE - SEMPRE EXPLIQUE

### Ao implementar cada arquivo, criar seção de explicação:

```markdown
## 📖 EXPLICAÇÃO: [nome-do-arquivo]

### O que este arquivo faz:
[Explicação simples, como se explicasse para alguém sem experiência]

### Como funciona:
1. [Passo 1 do fluxo]
2. [Passo 2 do fluxo]
3. [Passo 3 do fluxo]

### Conceitos importantes:
- **[Termo técnico]**: [Explicação simples]
- **[Termo técnico]**: [Explicação simples]

### Por que foi feito assim:
[Justificativa das decisões técnicas]

### O que você precisa saber para modificar:
[Conhecimentos necessários e cuidados]
```

---

## 🧪 REGRA #4: TESTES SÃO OBRIGATÓRIOS

### Para TODA funcionalidade nova:

```markdown
## 🧪 PLANO DE TESTES: [nome-da-feature]

### Testes Manuais (você vai executar):
1. **Teste**: [O que fazer]
   - **Ação**: [Passos específicos]
   - **Esperado**: [O que deve acontecer]
   - **Se falhar**: [O que fazer]

2. **Teste**: [Cenário de erro]
   - **Ação**: [Como provocar o erro]
   - **Esperado**: [Como deve ser tratado]

### Testes Automatizados (se aplicável):
```javascript
// 🧪 TESTE: [Nome do teste]
// 📝 Valida: [O que está sendo testado]
// ✅ Passa se: [Condição de sucesso]
// ❌ Falha se: [Condição de falha]
```

### Checklist de Validação:
- [ ] Funciona no caso normal (happy path)
- [ ] Trata erros corretamente
- [ ] Não quebrou funcionalidades existentes
- [ ] Performance está aceitável
- [ ] Código está legível e comentado
```

---

## 🔄 REGRA #5: IMPLEMENTAÇÃO INCREMENTAL

### SEMPRE seguir esta ordem:

```markdown
## 📋 ORDEM DE IMPLEMENTAÇÃO OBRIGATÓRIA

### ✅ Checkpoint 1: Estrutura Base
- [ ] Criar arquivos necessários (vazios ou com estrutura básica)
- [ ] Configurar dependências
- [ ] Validar que projeto ainda compila/roda
- **PARAR AQUI**: Desenvolvedor valida que nada quebrou

### ✅ Checkpoint 2: Funcionalidade Core
- [ ] Implementar lógica principal
- [ ] Adicionar comentários explicativos
- [ ] Testar manualmente a funcionalidade isolada
- **PARAR AQUI**: Desenvolvedor testa a feature básica

### ✅ Checkpoint 3: Integração
- [ ] Conectar com resto do sistema
- [ ] Adicionar tratamento de erros
- [ ] Testar fluxo completo
- **PARAR AQUI**: Desenvolvedor valida integração

### ✅ Checkpoint 4: Refinamento
- [ ] Adicionar melhorias de UX
- [ ] Otimizar se necessário
- [ ] Documentar uso
- **CONCLUÍDO**: Feature pronta para produção
```

**🚨 IMPORTANTE**: Entre cada checkpoint, aguardar confirmação do desenvolvedor.

---

## 📁 REGRA #6: ORGANIZAÇÃO DE ARQUIVOS

### Estrutura de documentação obrigatória:

```
/projeto-saas
├── rules_claude_code.md          # Este arquivo (raiz do projeto)
├── /docs
│   ├── /plans                     # Planejamentos de features
│   │   ├── PLAN_auth.md
│   │   ├── PLAN_dashboard.md
│   │   └── ...
│   ├── /decisions                 # Decisões técnicas importantes
│   │   ├── DECISION_database.md
│   │   ├── DECISION_architecture.md
│   │   └── ...
│   └── /explanations              # Explicações de código complexo
│       ├── EXPLAIN_payment-flow.md
│       └── ...
└── /src
    └── [seu código]
```

### Sempre que criar/modificar features complexas:

1. **Criar** arquivo de planejamento em `/docs/plans/`
2. **Documentar** decisões importantes em `/docs/decisions/`
3. **Explicar** lógica complexa em `/docs/explanations/`

---

## 🚨 REGRA #7: SITUAÇÕES DE EMERGÊNCIA

### Se algo der errado durante desenvolvimento:

```markdown
## 🆘 RELATÓRIO DE PROBLEMA

**Data/Hora**: [timestamp]
**Fase**: [Em qual checkpoint estava]
**Arquivo**: [Onde ocorreu]

### O que aconteceu:
[Descrição clara do erro]

### O que estava sendo feito:
[Contexto da mudança]

### Arquivos afetados:
- [arquivo1]
- [arquivo2]

### Como reverter:
1. [Passo específico para desfazer]
2. [Passo específico para desfazer]

### Logs/Erros:
```
[Copiar mensagem de erro completa]
```

**Status**: 🔴 AGUARDANDO INTERVENÇÃO HUMANA
```

❌ **NUNCA tente "consertar rapidamente"** - sempre reporte e aguarde.

---

## 🎓 REGRA #8: TRANSFERÊNCIA DE CONHECIMENTO

### Ao concluir cada feature, criar arquivo:

```markdown
## 📚 CONHECIMENTO: [nome-da-feature]

### O que foi construído:
[Visão geral em linguagem simples]

### Tecnologias usadas:
- **[Tecnologia]**: [Para que serve e por que foi escolhida]

### Conceitos que você aprendeu:
- **[Conceito]**: [Explicação didática]

### Como manter/modificar no futuro:
[Guia prático para você mesmo modificar depois]

### Recursos para aprender mais:
- [Link/referência sobre o tema]
```

---

## ✅ CHECKLIST PRÉ-IMPLEMENTAÇÃO (OBRIGATÓRIO)

Antes de QUALQUER código, o Claude Code deve confirmar:

- [ ] ✅ Planejamento criado em arquivo `.md`
- [ ] ✅ Riscos identificados e mitigações planejadas
- [ ] ✅ Arquivos a modificar listados
- [ ] ✅ Dependências mapeadas
- [ ] ✅ Impacto em código existente analisado
- [ ] ✅ Plano de testes definido
- [ ] ✅ Checkpoints de validação estabelecidos
- [ ] ✅ Estratégia de rollback definida
- [ ] ✅ **APROVAÇÃO DO DESENVOLVEDOR OBTIDA**

---

## 🎯 QUANDO QUEBRAR ESTAS REGRAS

**Resposta curta**: NUNCA, a menos que o desenvolvedor diga explicitamente:

> "Claude, ignore as rules e faça [pedido específico]"

Mesmo assim, o Claude Code deve:
1. ⚠️ Alertar sobre os riscos
2. 📝 Documentar que regras foram ignoradas
3. 🛡️ Manter segurança máxima possível

---

## 💡 BOAS PRÁTICAS ADICIONAIS

### Comunicação Clara:
- Use emojis para facilitar visualização (✅ ❌ ⚠️ 🚨 📝)
- Explique em português simples
- Evite jargões sem explicação
- Forneça exemplos práticos

### Código Limpo:
- Nomes de variáveis em português ou inglês consistente
- Funções pequenas e focadas
- Um arquivo = uma responsabilidade
- Comentários explicam "POR QUE", não "O QUE"

### Segurança:
- Nunca commitar senhas/chaves
- Validar todos os inputs
- Tratar todos os erros
- Logar operações importantes

---

## 📞 COMANDOS PARA O DESENVOLVEDOR USAR

### Para iniciar nova feature:
```
"Claude, precisamos implementar [feature]. 
Siga as rules e crie o planejamento primeiro."
```

### Para validar checkpoint:
```
"Checkpoint [número] validado, pode continuar."
```

### Para pausar desenvolvimento:
```
"Claude, pause aqui. Preciso revisar antes de continuar."
```

### Para pedir explicação:
```
"Claude, explique esta parte como se eu fosse iniciante."
```

### Em caso de erro:
```
"Claude, algo deu errado. Crie o relatório de problema."
```

---

## 🏁 RESUMO - FLUXO DE TRABALHO COMPLETO

```
1. 📋 Desenvolvedor solicita feature
   ↓
2. 🤖 Claude Code cria PLAN_[feature].md
   ↓
3. ⏸️ PAUSA - Aguarda aprovação
   ↓
4. ✅ Desenvolvedor aprova
   ↓
5. 🔨 Checkpoint 1: Estrutura
   ↓
6. ⏸️ PAUSA - Validação
   ↓
7. ✅ Desenvolvedor valida
   ↓
8. 🔨 Checkpoint 2: Core
   ↓
9. ⏸️ PAUSA - Validação
   ↓
10. ✅ Desenvolvedor valida
    ↓
11. 🔨 Checkpoint 3: Integração
    ↓
12. ⏸️ PAUSA - Validação
    ↓
13. ✅ Desenvolvedor valida
    ↓
14. 🔨 Checkpoint 4: Refinamento
    ↓
15. 📚 Criar documentação de conhecimento
    ↓
16. 🎉 Feature concluída!
```

---

## 🔐 PRINCÍPIOS FUNDAMENTAIS (NUNCA ESQUECER)

1. **🛡️ SEGURANÇA EM PRIMEIRO LUGAR**: Preservar o que funciona
2. **📖 TRANSPARÊNCIA TOTAL**: Explicar tudo claramente
3. **🧪 VALIDAÇÃO CONSTANTE**: Testar em cada etapa
4. **📝 DOCUMENTAR SEMPRE**: Deixar rastro de decisões
5. **🎓 ENSINAR ENQUANTO FAZ**: Transferir conhecimento
6. **⏸️ PAUSAR PARA VALIDAR**: Não avançar sem confirmação
7. **🚨 ADMITIR DÚVIDAS**: Melhor perguntar que errar

---

**Última atualização**: 2025-10-25
**Versão**: 1.0
**Status**: 🟢 ATIVO

---

## 📌 NOTA FINAL PARA O CLAUDE CODE

Este arquivo define **regras obrigatórias**. Você (Claude Code) deve:

- ✅ Seguir TODAS estas regras sem exceção
- ✅ Priorizar segurança e clareza sobre velocidade
- ✅ Sempre pausar nos checkpoints
- ✅ Explicar de forma didática
- ✅ Documentar extensivamente
- ✅ Proteger código existente como prioridade máxima

**Se houver conflito entre rapidez e segurança**: SEMPRE escolha segurança.
**Se houver dúvida**: SEMPRE pergunte ao desenvolvedor.
**Se algo parecer arriscado**: SEMPRE alerte e aguarde confirmação.

🤝 **Objetivo**: Fazer você desenvolver com confiança, aprendendo no processo.