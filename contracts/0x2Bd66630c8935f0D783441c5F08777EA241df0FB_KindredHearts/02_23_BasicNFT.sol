// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract BasicNFT is ERC721Enumerable {
    constructor(string memory name_, string memory sym_, string memory baseTokenURI_) ERC721(name_, sym_) {
    _baseTokenURI = baseTokenURI_;
    }
    string internal _baseTokenURI = "";
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /**
    * @dev return array of tokenIds owned by user
    */
    function getMyTokens(address me) public view returns (uint256[] memory) {
        uint256 bal = balanceOf(me);
        uint256[] memory wallet = new uint256[](bal);
        for (uint256 i = 0; i < bal; i++) {
            wallet[i] = tokenOfOwnerByIndex(me, i);
        }
        return wallet;
    }


  
    function getAllOwners() public view returns (address[] memory){
        uint256 supply = totalSupply();
        address[] memory owners = new address[](supply);
        
        for (uint256 id_ = 1; id_ < supply; id_++ ){
            owners[id_] = ownerOf(id_);
        }
        return owners;
    }
    
    /**
    * @dev burn nft (forever)
    */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    // solhint-disable
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
        //     return true;
        // }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}