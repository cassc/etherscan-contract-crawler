// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mentoria Compliance LGPD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//    MENTORIA Compliance LGPD, direcionada à implementação do programa de governança e privacidade de dados.                                                                       //
//                                                                                                                                                                                   //
//    CARGA HORÁRIA E SUPORTE TÉCNICO                                                                                                                                                //
//    •	Participação de até 03 pessoas por empresa mentorada.                                                                                                                     //
//    •	10 reuniões on-line de cerca de 1:30h semanal, perfazendo um total de 16 horas de mentoria.                                                                                 //
//    •	06 horas de consultoria individual, que podem ser cumulativas; ficando à critério do mentorado, usá-las quando sentir mais necessidade.                                      //
//    •	Uso gratuito do software de conformidade 'Be Compliance' durante o período de mentoria (4 meses).                                                                           //
//                                                                                                                                                                                   //
//    METODOLOGIA                                                                                                                                                                    //
//                                                                                                                                                                                   //
//    1.	Diagnóstico e Planejamento                                                                                                                                                 //
//    Troca de experiências para encontrar soluções para os reais problemas da empresa e elaboração do planejamento do projeto. Definição de funções e responsabilidades.     //
//                                                                                                                                                                                   //
//    2.	Mapeamento dos dados                                                                                                                                                        //
//    •	Data Mapping                                                                                                                                                                 //
//    •	Gap Analysis                                                                                                                                                                 //
//                                                                                                                                                                                   //
//    3.	Implementação                                                                                                                                                             //
//    •	Plano de ação                                                                                                                                                              //
//    •	Adequação da segurança jurídica da empresa (contratos, políticas e procedimentos)                                                                                       //
//    •	Adequação da segurança da informação (implementação das medidas de proteção baseadas na família ISO 27.000)                                                         //
//    •	Adequação do banco de dados.                                                                                                                                               //
//    •	Treinamento e Conscientização                                                                                                                                              //
//                                                                                                                                                                                   //
//    ENTREGÁVEIS                                                                                                                                                                    //
//    Mais de 800 páginas com modelos de documentos, e-books, jogos interativos para treinamento etc.                                                                                //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
//                                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MLGPD is ERC721Creator {
    constructor() ERC721Creator("Mentoria Compliance LGPD", "MLGPD") {}
}