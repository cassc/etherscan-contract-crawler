// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IERC721A, ERC721A} from './ERC721A.sol';
import {Ownable} from './Ownable.sol';
import {OperatorFilterer} from './OperatorFilterer.sol';
import {IERC2981, ERC2981} from './ERC2981.sol';

error SoldOut();
error CantWithdrawFunds();
error StakingNotActive();
error SenderNotOwner();
error AlreadyStaked();
error TokenIsStaked();
error NotStaked();

contract ChibimonTrainer is ERC721A, OperatorFilterer, Ownable, ERC2981 {

    string public baseURI;
    uint256 public maxSupply;
    bool public stakingStatus;
    bool public operatorFilteringEnabled;

    mapping(uint256 => uint256) public tokenStaked;

    constructor() ERC721A("Chibimon Trainer", "CMTRNR") {

        _registerForOperatorFiltering();

        maxSupply = 600;
        stakingStatus = false;
        operatorFilteringEnabled = true;

        _setDefaultRoyalty(msg.sender, 750);
    }

    // public functions

    /**
     * @dev Stake the given token
     */
    function stake(uint256 tokenId) public {
        if( !stakingStatus ) revert StakingNotActive();
        if( msg.sender != ownerOf(tokenId) && msg.sender != owner() ) revert SenderNotOwner();
        if( tokenStaked[tokenId] != 0 ) revert AlreadyStaked();

        tokenStaked[tokenId] = block.timestamp;
    }

    /**
     * @dev Unstake the given token
     */
    function unstake(uint256 tokenId) public {
        if( msg.sender != ownerOf(tokenId) && msg.sender != owner() ) revert SenderNotOwner();
        if( tokenStaked[tokenId] == 0 ) revert NotStaked();

        tokenStaked[tokenId] = 0;
    }

    /**
     * @dev Batch stake/unstake the given tokens
     */
    function batchStakeStatus(uint256[] memory tokenIds, bool status) external {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (status) {
                stake(tokenId);
            } else {
                unstake(tokenId);
            }
        }
    }

    /**
     * @dev Returns the tokenIds of the given address
     */ 
    function tokensOf(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256[] memory tokenIds = new uint256[](balanceOf(owner));
            uint256 tokenIdsIdx;

            for (uint256 i; i < totalSupply(); i++) {

                TokenOwnership memory ownership = _ownershipOf(i);

                if (ownership.burned || ownership.addr == address(0)) {
                    continue;
                }

                if (ownership.addr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }

            }

            return tokenIds;
        }
    }

    // owner functions

    /**
     * @dev Batch aidrop tokens to given addresses (onlyOwner)
     */
    function airdrop(address[] calldata receivers ) external onlyOwner {

        uint256 totalQuantity = receivers.length;

        if( totalSupply() + totalQuantity > maxSupply ) revert SoldOut();

        for( uint256 i = 0; i < receivers.length; i++ ) {
            _mint(receivers[i], 1);
        }
    }

    /**
     * @dev Batch aidrop tokens to given addresses (onlyOwner)
     */
    function airdropWithQuantity(address[] calldata receivers, uint256[] calldata quantities ) external onlyOwner {

        uint256 totalQuantity = 0;

        for( uint256 i = 0; i < quantities.length; i++ ) {
            totalQuantity += quantities[i];
        }

        if( totalSupply() + totalQuantity > maxSupply ) revert SoldOut();

        for( uint256 i = 0; i < receivers.length; i++ ) {
            _mint(receivers[i], quantities[i]);
        }
    }

    /**
     * @dev Set base uri for token metadata (onlyOwner)
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * @dev Enable/Disable staking (onlyOwner)
     */
    function setStakingStatus(bool status) external onlyOwner {
        stakingStatus = status;
    }

    /**
     * @dev Withdraw all funds (onlyOwner)
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if( !success ) revert CantWithdrawFunds();
    }

    // overrides / royalities

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        if( tokenStaked[tokenId] != 0 ) revert TokenIsStaked();
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        if( tokenStaked[tokenId] != 0 ) revert TokenIsStaked();
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        if( tokenStaked[tokenId] != 0 ) revert TokenIsStaked();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }

}