// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
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
}



contract NAEOE is ContextMixin, ERC1155Supply, Ownable, Pausable {
    
    string public name;
    string public symbol;
    string public contractBaseURI;
    address private proxyAddress;

    constructor(
        string memory _baseUri, 
        string memory _baseContractURI,
        string memory _name,
        string memory _symbol
    ) ERC1155(_baseUri) {
        setBaseTokenURI(_baseUri);
        setBaseContractURI(_baseContractURI);
        name = _name;
        symbol = _symbol;
        proxyAddress = _msgSender();
    }

    // contract metadata for opensea.io
    function contractURI() public view returns (string memory) {
        return contractBaseURI;
    }

    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }

    /**
    * @dev set a new proxy address
    **/ 
    function setProxy(
        address newProxy
    ) public onlyOwner {
        proxyAddress = newProxy;
    }    

    /**
    * @dev return the address of proxy
    **/ 
    function getProxy() public view returns (address) {
        return proxyAddress;
    }   

    /**
    * @dev mint token
    **/ 
    function mintMultiToken(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        require( (_msgSender() == owner()), "Only owner can mint!");
        super._mint(_to, _tokenId, _amount, "");
    }

    /**
    * @dev mint token (batch)
    **/ 
    function mintMultiToken(
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) public {
        require( (_msgSender() == owner()), "Only owner can mint!");
        super._mintBatch(_to, _tokenIds, _amounts, "");
    }

    /**
    * @dev set token URI
    **/ 
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        super._setURI(_baseTokenURI);
    }

    /**
    * @dev set contract metadata URI
    **/ 
    function setBaseContractURI(string memory _baseContractURI) public onlyOwner {
        contractBaseURI = _baseContractURI;
    }    

    /**
    * @dev burn token
    **/ 
    function burn(address account, uint256 id, uint256 amount) public onlyOwner {
        super._burn(account, id, amount);
    }   

    /**
    * @dev burn token (batch)
    **/ 
    function burn(address account, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {
        super._burnBatch(account, ids, amounts);
    }

    /**
    * @dev pause token
    **/ 
    function pauseToken() public onlyOwner {
        super._pause();
    }

    /**
    * @dev unpause token
    **/ 
    function unpauseToken() public onlyOwner {
        super._unpause();
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        return string(
            abi.encodePacked(
                super.uri(0),
                bytes("/"),
                uint2str(_tokenId)
            )
        );
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        return string(bstr);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    /**
    * Override isApprovedForAll to auto-approve OS's proxy contract
    * https://docs.opensea.io/docs/polygon-basic-integration
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
       if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // for 3PM proxy address
        if (_operator == proxyAddress) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}