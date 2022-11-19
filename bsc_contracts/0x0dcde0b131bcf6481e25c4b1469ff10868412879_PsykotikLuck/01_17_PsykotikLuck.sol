// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "./libraries/Base64.sol";  
import './libraries/ERC2981PerTokenRoyalties.sol';
import "hardhat/console.sol";
 
// inherits from ERC721, which is the standard NFT contract!
contract PsykotikLuck is ERC721URIStorage, ERC2981PerTokenRoyalties {
    
    constructor() ERC721 ("PPCARDS V2 Psykotik Luck", "PPCARDS V2") {
        console.log("This is PPCARD NFT contract. Woah!");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base) 
        returns (bool)
    {  
        return super.supportsInterface(interfaceId);
    }
 
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
 
    string[] psykotikLuckArray = [ //9 perso
        //0 big_b 10ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiQklHX0IiLAogICAgImRlc2NyaXB0aW9uIjogIkJpZ19CIFBzeWtvdGlrTHVjayBQUGFyZCBQc3lrb3Rpa1BhbmRhIiwgCiAgICAiaW1hZ2UiOiAgImh0dHBzOi8vYmFmeWJlaWd6NnFpcDNhb2cyZ3hkcDJqbWY1ZmJ0Ymdwd2Q1bzc1dXBiZmd5ZGZvbWpoa3FweTZuY3UuaXBmcy5uZnRzdG9yYWdlLmxpbmsvYmlnX2IubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9iaWdfYi5tcDQiCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiSGVhbHRoIFBvaW50cyIsIAogICAgICAgICAgICAidmFsdWUiOiAxMDAgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIEF0dGFjayBEYW1hZ2UiLCAKICAgICAgICAgICAgInZhbHVlIjogMAogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyB3ZWFwb24iCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiR2VuZGVyIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJtYWxlIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gcG93ZXIiIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIE5hbWUiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIERlc2MiLCAKICAgICAgICAgICAgInZhbHVlIjogIm9uIHBvd2VyIiAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkJpcnRoIERhdGUiLCAKICAgICAgICAgICAgInZhbHVlIjogIiIgCiAgICAgICAgfQogICAgICAgIF0KICAgIH0=", 
        //1 burned 50ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiQlVSTkVEIiwKICAgICJkZXNjcmlwdGlvbiI6ICJCVVJORUQgUHN5a290aWtMdWNrIFBQYXJkIFBzeWtvdGlrUGFuZGEiLCAKICAgICJpbWFnZSI6ICAiaHR0cHM6Ly9iYWZ5YmVpZ3o2cWlwM2FvZzJneGRwMmptZjVmYnRiZ3B3ZDVvNzV1cGJmZ3lkZm9tamhrcXB5Nm5jdS5pcGZzLm5mdHN0b3JhZ2UubGluay9idXJuZWQubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9idXJuZWQubXA0IgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAKICAgICAgICAgICAgInZhbHVlIjogMTAwIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiBBdHRhY2sgRGFtYWdlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6IDAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gd2VhcG9uIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkdlbmRlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibWFsZSIgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiUG93ZXIiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBOYW1lIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyBwb3dlciIKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBEZXNjIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyBwb3dlciIgCiAgICAgICAgfSAsCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiQmlydGggRGF0ZSIsIAogICAgICAgICAgICAidmFsdWUiOiAiIiAKICAgICAgICB9CiAgICBdCn0=", 
        //2 burned_shiny 5ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiQlVSTkVEIFNISU5ZIiwKICAgICJkZXNjcmlwdGlvbiI6ICJCVVJORUQgU0hJTlkgUHN5a290aWtMdWNrIFBQYXJkIFBzeWtvdGlrUGFuZGEiLCAKICAgICJpbWFnZSI6ICAiaHR0cHM6Ly9iYWZ5YmVpZ3o2cWlwM2FvZzJneGRwMmptZjVmYnRiZ3B3ZDVvNzV1cGJmZ3lkZm9tamhrcXB5Nm5jdS5pcGZzLm5mdHN0b3JhZ2UubGluay9idXJuZWRfc2hpbnkubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9idXJuZWRfc2hpbnkubXA0IgogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiSGVhbHRoIFBvaW50cyIsIAogICAgICAgICAgICAidmFsdWUiOiAxMDAgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIEF0dGFjayBEYW1hZ2UiLCAKICAgICAgICAgICAgInZhbHVlIjogMAogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyB3ZWFwb24iCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiR2VuZGVyIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJtYWxlIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gcG93ZXIiIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIE5hbWUiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIERlc2MiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIiAKICAgICAgICB9ICwKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJCaXJ0aCBEYXRlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICIiIAogICAgICAgIH0KICAgIF0KfQ==", 
        //3 grrrrr 50ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiR1JSUlJSIiwKICAgICJkZXNjcmlwdGlvbiI6ICJHUlJSUlIgUHN5a290aWtMdWNrIFBQYXJkIFBzeWtvdGlrUGFuZGEiLCAKICAgICJpbWFnZSI6ICAiaHR0cHM6Ly9iYWZ5YmVpZ3o2cWlwM2FvZzJneGRwMmptZjVmYnRiZ3B3ZDVvNzV1cGJmZ3lkZm9tamhrcXB5Nm5jdS5pcGZzLm5mdHN0b3JhZ2UubGluay9ncnJycnIubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9ncnJycnIubXA0IgogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiSGVhbHRoIFBvaW50cyIsIAogICAgICAgICAgICAidmFsdWUiOiAxMDAgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIEF0dGFjayBEYW1hZ2UiLCAKICAgICAgICAgICAgInZhbHVlIjogMAogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyB3ZWFwb24iCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiR2VuZGVyIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJtYWxlIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gcG93ZXIiIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIE5hbWUiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIERlc2MiLCAKICAgICAgICAgICAgInZhbHVlIjogIm9uIHBvd2VyIiAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkJpcnRoIERhdGUiLCAKICAgICAgICAgICAgInZhbHVlIjogIiIgCiAgICAgICAgfSAKICAgIF0KfQ==", 
        //4 magnuum 10ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiTUFHTlVVTSIsCiAgICAiZGVzY3JpcHRpb24iOiAiTUFHTlVVTSBQc3lrb3Rpa0x1Y2sgUFBhcmQgUHN5a290aWtQYW5kYSIsIAogICAgImltYWdlIjogICJodHRwczovL2JhZnliZWlnejZxaXAzYW9nMmd4ZHAyam1mNWZidGJncHdkNW83NXVwYmZneWRmb21qaGtxcHk2bmN1LmlwZnMubmZ0c3RvcmFnZS5saW5rL21hZ251dW0ubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9tYWdudXVtLm1wNCIKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAKICAgICAgICAgICAgInZhbHVlIjogMTAwIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiBBdHRhY2sgRGFtYWdlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6IDAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gd2VhcG9uIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkdlbmRlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibWFsZSIgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiUG93ZXIiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBOYW1lIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyBwb3dlciIKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBEZXNjIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJvbiBwb3dlciIgCiAgICAgICAgfSwKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJCaXJ0aCBEYXRlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICIiIAogICAgICAgIH0gCiAgICBdCn0=", 
        //5 nothing_card 100ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiTk9USElOR19DQVJEIiwKICAgICJkZXNjcmlwdGlvbiI6ICJOT1RISU5HX0NBUkQgUHN5a290aWtMdWNrIFBQYXJkIFBzeWtvdGlrUGFuZGEiLCAKICAgICJpbWFnZSI6ICAiaHR0cHM6Ly9iYWZ5YmVpZ3o2cWlwM2FvZzJneGRwMmptZjVmYnRiZ3B3ZDVvNzV1cGJmZ3lkZm9tamhrcXB5Nm5jdS5pcGZzLm5mdHN0b3JhZ2UubGluay9ub3RoaW5nX2NhcmQubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9ub3RoaW5nX2NhcmQubXA0IgogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiSGVhbHRoIFBvaW50cyIsIAogICAgICAgICAgICAidmFsdWUiOiAxMDAgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIEF0dGFjayBEYW1hZ2UiLCAKICAgICAgICAgICAgInZhbHVlIjogMAogICAgICAgIH0sCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiV2VhcG9uIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyB3ZWFwb24iCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiR2VuZGVyIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJtYWxlIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gcG93ZXIiIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIE5hbWUiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIERlc2MiLCAKICAgICAgICAgICAgInZhbHVlIjogIm9uIHBvd2VyIiAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkJpcnRoIERhdGUiLCAKICAgICAgICAgICAgInZhbHVlIjogIiIgCiAgICAgICAgfSAKICAgIF0KfQ==", 
        //6 pumpkin 50ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiUFVNUEtJTiIsCiAgICAiZGVzY3JpcHRpb24iOiAiUFVNUEtJTiBQc3lrb3Rpa0x1Y2sgUFBhcmQgUHN5a290aWtQYW5kYSIsIAogICAgImltYWdlIjogICJodHRwczovL2JhZnliZWlnejZxaXAzYW9nMmd4ZHAyam1mNWZidGJncHdkNW83NXVwYmZneWRmb21qaGtxcHk2bmN1LmlwZnMubmZ0c3RvcmFnZS5saW5rL3B1bXBraW4ubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9wdW1wa2luLm1wNCIKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAKICAgICAgICAgICAgInZhbHVlIjogMTAwIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiBBdHRhY2sgRGFtYWdlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6IDAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gd2VhcG9uIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkdlbmRlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibWFsZSIgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiUG93ZXIiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBOYW1lIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyBwb3dlciIKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBEZXNjIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJvbiBwb3dlciIgCiAgICAgICAgfSwKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJCaXJ0aCBEYXRlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICIiIAogICAgICAgIH0gCiAgICBdCn0=", 
        //7 pumpkin_shiny 5ex
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiUFVNUEtJTiBTSElOWSIsCiAgICAiZGVzY3JpcHRpb24iOiAiUFVNUEtJTiBTSElOWSBQc3lrb3Rpa0x1Y2sgUFBhcmQgUHN5a290aWtQYW5kYSIsIAogICAgImltYWdlIjogICJodHRwczovL2JhZnliZWlnejZxaXAzYW9nMmd4ZHAyam1mNWZidGJncHdkNW83NXVwYmZneWRmb21qaGtxcHk2bmN1LmlwZnMubmZ0c3RvcmFnZS5saW5rL3B1bXBraW5fc2hpbnkubXA0IiwKICAgICJhdHRyaWJ1dGVzIjogWyAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJsb2NhbF9tZWRpYSIsIAogICAgICAgICAgICAidmFsdWUiOiAiL25mdC9sdWNrL21wNC9wdW1wa2luX3NoaW55Lm1wNCIKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAKICAgICAgICAgICAgInZhbHVlIjogMTAwIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiBBdHRhY2sgRGFtYWdlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6IDAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gd2VhcG9uIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkdlbmRlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibWFsZSIgCiAgICAgICAgfSwgCiAgICAgICAgeyAKICAgICAgICAgICAgInRyYWl0X3R5cGUiOiAiUG93ZXIiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBOYW1lIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJubyBwb3dlciIKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciBEZXNjIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICJvbiBwb3dlciIgCiAgICAgICAgfSwKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJCaXJ0aCBEYXRlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICIiIAogICAgICAgIH0gCiAgICBdCn0=", 
        //8 uglydoll 50ex 
        "data:application/json;base64,ewogICAgIm5hbWUiOiAiVUdMWSBET0xMIiwKICAgICJkZXNjcmlwdGlvbiI6ICJVR0xZIERPTEwgUHN5a290aWtMdWNrIFBQYXJkIFBzeWtvdGlrUGFuZGEiLCAKICAgICJpbWFnZSI6ICAiaHR0cHM6Ly9iYWZ5YmVpZ3o2cWlwM2FvZzJneGRwMmptZjVmYnRiZ3B3ZDVvNzV1cGJmZ3lkZm9tamhrcXB5Nm5jdS5pcGZzLm5mdHN0b3JhZ2UubGluay91Z2x5ZG9sbC5tcDQiLAogICAgImF0dHJpYnV0ZXMiOiBbIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogImxvY2FsX21lZGlhIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6ICIvbmZ0L2x1Y2svbXA0L3VnbHlkb2xsLm1wNCIKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkhlYWx0aCBQb2ludHMiLCAKICAgICAgICAgICAgInZhbHVlIjogMTAwIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiBBdHRhY2sgRGFtYWdlIiwgCiAgICAgICAgICAgICJ2YWx1ZSI6IDAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIldlYXBvbiIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gd2VhcG9uIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkdlbmRlciIsIAogICAgICAgICAgICAidmFsdWUiOiAiZmVtYWxlIiAKICAgICAgICB9LCAKICAgICAgICB7IAogICAgICAgICAgICAidHJhaXRfdHlwZSI6ICJQb3dlciIsIAogICAgICAgICAgICAidmFsdWUiOiAibm8gcG93ZXIiIAogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIE5hbWUiLCAKICAgICAgICAgICAgInZhbHVlIjogIm5vIHBvd2VyIgogICAgICAgIH0sIAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIlBvd2VyIERlc2MiLCAKICAgICAgICAgICAgInZhbHVlIjogIm9uIHBvd2VyIiAKICAgICAgICB9LAogICAgICAgIHsgCiAgICAgICAgICAgICJ0cmFpdF90eXBlIjogIkJpcnRoIERhdGUiLCAKICAgICAgICAgICAgInZhbHVlIjogIiIgCiAgICAgICAgfSAKICAgIF0KfQ=="
    ];

    function mint(
        uint pandaTabId,
        uint256 royaltyValue 
    ) external {
        uint256 newItemId = _tokenIds.current();
        address royaltyRecipient = 0xBd84d11E616910A30A0aed13Baaa8d715A0cb0Bc;
         
        string memory item = psykotikLuckArray[pandaTabId];
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
    }



    function mintLucky1ex (
        uint pandaTabId,
        uint256 royaltyValue 
    ) external {
        uint256 newItemId = _tokenIds.current();
        address royaltyRecipient = 0xBd84d11E616910A30A0aed13Baaa8d715A0cb0Bc;
         
        string memory item = psykotikLuckArray[pandaTabId];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
        
    }

   
    function mintLucky2ex (
        uint pandaTabId1,
        uint pandaTabId2,
        uint256 royaltyValue 
    ) external {
        uint256 newItemId = _tokenIds.current();
        address royaltyRecipient = 0xBd84d11E616910A30A0aed13Baaa8d715A0cb0Bc;
         
        string memory item = psykotikLuckArray[pandaTabId1];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
        newItemId = _tokenIds.current();

        item = psykotikLuckArray[pandaTabId2];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
        
    }


    function mintLucky5ex (
        uint pandaTabId1,
        uint pandaTabId2,
        uint pandaTabId3,
        uint pandaTabId4,
        uint pandaTabId5,
        uint256 royaltyValue 
    ) external {
        uint256 newItemId = _tokenIds.current();
        address royaltyRecipient = 0xBd84d11E616910A30A0aed13Baaa8d715A0cb0Bc;
        
        string memory item = psykotikLuckArray[pandaTabId1];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
         _tokenIds.increment();
         
         

        item = psykotikLuckArray[pandaTabId2];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
         


        item = psykotikLuckArray[pandaTabId3];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
         


        item = psykotikLuckArray[pandaTabId4];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
         newItemId = _tokenIds.current();


        item = psykotikLuckArray[pandaTabId5];
        _safeMint(msg.sender, newItemId, '');
        _setTokenURI(newItemId, item);
        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
        if (royaltyValue > 0) {
            _setTokenRoyalty(newItemId, royaltyRecipient, royaltyValue );
        }
        _tokenIds.increment();
        newItemId = _tokenIds.current();
        
    }

}