// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155Holder} from '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol';
import {ERC721Holder} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import {IEns} from '../interfaces/IEns.sol';
import {IReverseRegistrar} from '../interfaces/external/ens/IReverseRegistrar.sol';
import {ENS} from '../interfaces/external/ens/ENS.sol';
import {INameWrapper} from '../interfaces/external/ens/INameWrapper.sol';
import {LibDiamond} from '../libraries/LibDiamond.sol';

contract Ens is IEns, ERC1155Holder, ERC721Holder {
  function ensSetReverseName(address reverseRegistrar, string memory name) external {
    LibDiamond.enforceIsContractOwner();

    IReverseRegistrar(reverseRegistrar).setName(name);
  }

  function ensUnwrap(address nameWrapper, bytes32 labelHash) external {
    LibDiamond.enforceIsContractOwner();

    INameWrapper(nameWrapper).unwrapETH2LD(labelHash, address(this), address(this));
  }

  function ensSetApprovalForAll(address registry, address operator, bool approved) external {
    LibDiamond.enforceIsContractOwner();

    ENS(registry).setApprovalForAll(operator, approved);
  }
}