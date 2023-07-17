// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IEvidenzSingleAsset is IERC165, IERC721 {
    function setDescription(string calldata description_) external;

    function setImage(string calldata image_) external;

    function setTermsOfUse(string calldata termsOfUse_) external;
}