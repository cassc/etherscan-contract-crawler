// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface FTNFTData {
    struct TemplateStruct {
        uint256                  templateId;
        string                   name;
        string                   image;
        uint256                  price;
        uint256                  amount;
        uint256                  issue;
        bool                     enable;
    }
}