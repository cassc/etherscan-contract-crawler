// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Lead With... ™
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                //
//                                                                                                                                                                //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::'######::::::'###::::'##:::::::'##:::::::'########:'########::'##:::'##:::::'#######::'########:::::'######::::'#######:::'#######::'########:®:::      //
//    :::'##... ##::::'## ##::: ##::::::: ##::::::: ##.....:: ##.... ##:. ##:'##:::::'##.... ##: ##.....:::::'##... ##::'##.... ##:'##.... ##: ##.... ##::::      //
//    ::: ##:::..::::'##:. ##:: ##::::::: ##::::::: ##::::::: ##:::: ##::. ####:::::: ##:::: ##: ##:::::::::: ##:::..::: ##:::: ##: ##:::: ##: ##:::: ##::::      //
//    ::: ##::'####:'##:::. ##: ##::::::: ##::::::: ######::: ########::::. ##::::::: ##:::: ##: ######:::::: ##::'####: ##:::: ##: ##:::: ##: ##:::: ##::::      //
//    ::: ##::: ##:: #########: ##::::::: ##::::::: ##...:::: ##.. ##:::::: ##::::::: ##:::: ##: ##...::::::: ##::: ##:: ##:::: ##: ##:::: ##: ##:::: ##::::      //
//    ::: ##::: ##:: ##.... ##: ##::::::: ##::::::: ##::::::: ##::. ##::::: ##::::::: ##:::: ##: ##:::::::::: ##::: ##:: ##:::: ##: ##:::: ##: ##:::: ##::::      //
//    :::. ######::: ##:::: ##: ########: ########: ########: ##:::. ##:::: ##:::::::. #######:: ##::::::::::. ######:::. #######::. #######:: ########:::::      //
//    ::::......::::..:::::..::........::........::........::..:::::..:::::..:::::::::.......:::..::::::::::::......:::::.......::::.......:::........::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//    ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::      //
//                                                                                                                                                                //
//    "Lead with...™: A curation of 1/1 original illustrations by renowned artist (and former lawyer) Dori Desautel Broudy, presented for the first time in       //
//    NFT/digital collectible form.                                                                                                                               //
//                                                                                                                                                                //
//    A commentary on the various ways in which strong leadership is demonstrated, the first phase of Dori's latest collection includes works in honor of         //
//    leading with (and through) advocacy, with 51% of the net proceeds from the sale of each piece routed to organizations offering a voice for those in         //
//    need of representation-namely, the Lawyering Project (lawyeringproject.org); PeaceWomen: Women's International League for Peace & Freedom                   //
//    (peacewomen.org); and Everytown for Gun Safety (everytown.org).  Notably, Dori has chosen to abstain from collecting royalties in secondary sales for       //
//    this collection. Each successful NFT collector will also have the option to purchase the original, physical version of Dori's artwork or a single           //
//    edition print-an option never before made available-in a subsequent transaction, and will receive a diamond-cut, gallery-quality acrylic block              //
//    conversion of the NFT image bought.                                                                                                                         //
//                                                                                                                                                                //
//    Dori and her Gallery of Good®-celebrated in Forbes, Modern Luxury, Bella Magazine, Thrive Global and NBC, CBS and Fox Philadelphia affiliates, for          //
//    example-have supported more than two dozen charitable organizations worldwide, with retail relationships, commissioned works and special projects for       //
//    partners including the Four Seasons Hotel, Neiman Marcus, Penn Medicine's Abramson Cancer Center, CNN Hero Dr. Ala Stanford's Center for Health Equity,     //
//    and the City of Philadelphia.  Dori is routinely sought after to speak about her portfolio, mission and the inspiration behind her work, including most     //
//    recently at the University of Pennsylvania's Wharton School of Business.                                                                                    //
//                                                                                                                                                                //
//    Additional information may be found at www.doridesautelbroudy.com; Instagram: @doridesautelbroudy; Twitter: @DoridBroudy; or Dori's profile on LinkedIn.    //
//                                                                                                                                                                //
//    *The purchase of one of Dori's NFTs does not transfer any intellectual property rights to the successful buyer, and all copyright, trademark, and any       //
//    other right to commercially exploit each image remains with Dori Desautel Broudy, alone. At no time without specific, written authorization by Dori         //
//    Desautel Broudy may any images be produced in physical form or reproduced in any way.                                                                       //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
//                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DDB is ERC721Creator {
    constructor() ERC721Creator(unicode"Lead With... ™", "DDB") {}
}