// SPDX-License-Identifier: MIT
// ENVELOP (NIFTSY) protocol for NFT. Wrapper & Distributor contract
pragma solidity ^0.8.6;

import "WrapperWithERC20Collateral.sol";
import "IERC721Mintable.sol";

/**
 * @title ERC-721 Non-Fungible Token Wrapper 
 * @dev For wrpap existing ERC721 with ability add ERC20 collateral
 */
contract WrapperDistributor721 is WrapperWithERC20Collateral {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    
    
    mapping(address => bool) public distributors;

    event GasLimit(uint256 wrappedAmountCount, address lastReceiver);
    constructor (address _erc20) 
        WrapperWithERC20Collateral(_erc20) 
    {
        distributors[msg.sender] = true;

    }
    

    /// !!!!For gas safe this low levelfunction has NO any check before wrap
    /// So you have NO warranty to do Unwrap well
    function WrapAndDistrib721WithMint(
        address _original721, 
        address[] memory _receivers,
        uint256[] memory _tokenIds, 
        ERC20Collateral[] memory _forDistrib,
        uint256 _unwrapAfter
    ) public payable 
    {
        require(distributors[msg.sender], "Only for distributors");
        //require(_receivers.length <= 256, "Not more 256");
        require(_receivers.length == _tokenIds.length, "Not equal arrays");
        // topup wrapper contract with erc20 that would be added in collateral
        for (uint8 i = 0; i < _forDistrib.length; i ++) {
            IERC20(_forDistrib[i].erc20Token).safeTransferFrom(
                msg.sender, 
                address(this), 
                _forDistrib[i].amount * _receivers.length
            );
        }

        for (uint8 i = 0; i < _receivers.length; i ++) {
            // 1. Lits mint 721, but for gas save we will not do it for receiver
            // but wrapper contract as part of wrapp process
            IERC721Mintable(_original721).mint(address(this), _tokenIds[i]);

            // 2.Mint wrapped NFT for receiver and populate storage
            lastWrappedNFTId += 1;
            _mint(_receivers[i], lastWrappedNFTId);
            wrappedTokens[lastWrappedNFTId] = NFT(
                _original721, 
                _tokenIds[i], 
                msg.value / _receivers.length, // native blockchain asset
                0,                // accumalated fee token
                _unwrapAfter,     // timelock
                0,                //_transferFee,
                address(0),       // _royaltyBeneficiary,
                0,                //_royaltyPercent,
                0,                //_unwraptFeeThreshold,
                address(0),       //_transferFeeToken,
                AssetType.ERC721,
                0
            );

            // 3.Add erc20 collateral
            ERC20Collateral[] storage coll = erc20Collateral[lastWrappedNFTId];
            for (uint8 j = 0; j < _forDistrib.length; j ++) {
                coll.push(ERC20Collateral({
                    erc20Token: _forDistrib[j].erc20Token, 
                    amount: _forDistrib[j].amount
                }));
            }
            emit Wrapped(_original721, _tokenIds[i], lastWrappedNFTId);
            // Safe Emergency exit
            if (gasleft() <= 1_000) {
                emit GasLimit(i + 1, _receivers[i]);
                return;
            }   
        }
    }

        /// !!!!For gas safe this low levelfunction has NO any check before wrap
    /// So you have NO warranty to do Unwrap well
    function WrapAndDistribEmpty(
        address[] memory _receivers,
        ERC20Collateral[] memory _forDistrib,
        uint256 _unwrapAfter
    ) public payable 
    {
        require(distributors[msg.sender], "Only for distributors");
        require(_receivers.length <= 256, "Not more 256");
        //require(_receivers.length == _tokenIds.length, "Not equal arrays");
        // topup wrapper contract with erc20 that would be added in collateral
        for (uint8 i = 0; i < _forDistrib.length; i ++) {
            IERC20(_forDistrib[i].erc20Token).safeTransferFrom(
                msg.sender, 
                address(this), 
                _forDistrib[i].amount * _receivers.length
            );
        }

        for (uint8 i = 0; i < _receivers.length; i ++) {

            // 2.Mint wrapped NFT for receiver and populate storage
            lastWrappedNFTId += 1;
            _mint(_receivers[i], lastWrappedNFTId);
            wrappedTokens[lastWrappedNFTId] = NFT(
                address(0), // _original721, 
                0, // _tokenIds[i], 
                msg.value / _receivers.length, // native blockchain asset
                0,                // accumalated fee token
                _unwrapAfter,     // timelock
                0,                //_transferFee,
                address(0),       // _royaltyBeneficiary,
                0,                //_royaltyPercent,
                0,                //_unwraptFeeThreshold,
                address(0),       //_transferFeeToken,
                AssetType.UNDEFINED,
                0
            );

            // 3.Add erc20 collateral
            ERC20Collateral[] storage coll = erc20Collateral[lastWrappedNFTId];
            for (uint8 j = 0; j < _forDistrib.length; j ++) {
                coll.push(ERC20Collateral({
                    erc20Token: _forDistrib[j].erc20Token, 
                    amount: _forDistrib[j].amount
                }));
            }
            emit Wrapped(address(0), 0, lastWrappedNFTId);
            // Safe Emergency exit
            if (gasleft() <= 1_000) {
                emit GasLimit(i + 1, _receivers[i]);
                return;
            }   
        }
    }

    ////////////////////////////////////////////////////////////////
    //////////     Admins                                     //////
    ////////////////////////////////////////////////////////////////

    function setDistributorState(address _user, bool _state) external onlyOwner {
        distributors[_user] = _state;
    }
    ////////////////////////////////////////////////////////////////

    function _baseURI() internal view  override(ERC721) returns (string memory) {
        return 'https://envelop.is/distribmetadata/';
    }


    /**
     * @dev Function returns tokenURI of **underline original token** 
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        NFT storage nft = wrappedTokens[_tokenId];
        if (nft.tokenContract != address(0)) {
            return IERC721Metadata(nft.tokenContract).tokenURI(nft.tokenId);
        } else {
            return ERC721.tokenURI(_tokenId);
        }    
    }
}