// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import './IMinter.sol';
import '../library/LogReporting.sol';
import '../NFT/OneNFT.sol';
import '../NFT/MNA/AliceNFT.sol';

contract Minter is AccessControl, IMinter {
    using LogReporting for sLogReporting;

    bytes4 public constant ID_ERC721 = type(IERC721).interfaceId;
    bytes4 public constant ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
    sLogReporting private logger;

    constructor(address _admin, address _minter) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(MINTER_ROLE, _minter);
        logger = sLogReporting('Minter');
    }

    modifier _onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            logger.reportError('You are not allowed to perform this operation')
        );
        _;
    }

    function mintIds(
        address nftContract,
        address to,
        uint256[] memory tokenIds
    ) public _onlyMinter {
        require(to != address(0), logger.reportError('to must be different than 0x'));
        require(tokenIds.length > 0, logger.reportError('tokenIds must have at least one id'));
        OneNFT erc721Contract = OneNFT(nftContract);
        require(
            erc721Contract.supportsInterface(ID_ERC721),
            logger.reportError('Contract not found or not of type ERC721')
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            erc721Contract.mint(to, tokenIds[i]);
        }
    }

    function mintIdsTo(address nftContract, TokenAndAddress[] memory tokenIdsTo)
        public
        _onlyMinter
    {
        require(tokenIdsTo.length > 0, logger.reportError('tokenIds must have at least one id'));
        OneNFT erc721Contract = OneNFT(nftContract);
        require(
            erc721Contract.supportsInterface(ID_ERC721),
            logger.reportError('Contract not found or not of type ERC721')
        );
        for (uint256 i = 0; i < tokenIdsTo.length; i++) {
            require(
                tokenIdsTo[i].to != address(0),
                logger.reportError('to must be different than 0x')
            );
            erc721Contract.mint(tokenIdsTo[i].to, tokenIdsTo[i].tokenId);
        }
    }

    function mintAutoIds(
        address nftContract,
        address to,
        uint256 amount
    ) public _onlyMinter {
        require(to != address(0), logger.reportError('to must be different than 0x'));
        require(amount > 0, logger.reportError('amount must be greater than 0'));
        AliceNFT erc721EnumerableContract = AliceNFT(nftContract);
        require(
            erc721EnumerableContract.supportsInterface(ID_ERC721_ENUMERABLE),
            logger.reportError('Contract not found or not of type ERC721Enumerable')
        );
        mintEnumerable(erc721EnumerableContract, to, amount);
    }

    function mintAutoIdsTo(address nftContract, AmountAndAddress[] memory amountToAddresses)
        public
        _onlyMinter
    {
        require(
            amountToAddresses.length > 0,
            logger.reportError('tokenIds must have at least one id')
        );
        AliceNFT erc721EnumerableContract = AliceNFT(nftContract);
        require(
            erc721EnumerableContract.supportsInterface(ID_ERC721_ENUMERABLE),
            logger.reportError('Contract not found or not of type ERC721Enumerable')
        );
        for (uint256 i = 0; i < amountToAddresses.length; i++) {
            require(
                amountToAddresses[i].to != address(0),
                logger.reportError('to must be different than 0x')
            );
            require(
                amountToAddresses[i].amount > 0,
                logger.reportError('amount must be greater than 0')
            );
            mintEnumerable(
                erc721EnumerableContract,
                amountToAddresses[i].to,
                amountToAddresses[i].amount
            );
        }
    }

    function mintEnumerable(
        AliceNFT nft,
        address to,
        uint256 amount
    ) private {
        for (uint256 j = 0; j < amount; j++) {
            nft.safeMint(to);
        }
    }
}