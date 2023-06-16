// SPDX-License-Identifier: MIT
// Promos v1.0.0
// Creator: promos.wtf

pragma solidity ^0.8.0;

import "./IPromos.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract PromosProxy {
    address public promosMintAddress;
}

abstract contract Promos is IPromos, ERC165 {
    address public promosOwner;
    uint256 public promosSupply;
    address public promosProxyContract;
    address constant promosProxyContractMainnet = 0xA7296e3239Db13ACa886Fb130aE5Fe8f5A315721;
    address constant promosProxyContractTestnet = 0xf4Ac6561bCE3b841a354ee1eF827A3e48a78F152;
    
    constructor(uint256 _promosSupply, address _promosProxyContract) {
        promosOwner = msg.sender;
        promosSupply = _promosSupply;
        promosProxyContract = _promosProxyContract;
    }

    /**
     * @dev
     * This operation will delete all the ongoing campaigns
     */
    function transferPromosOwnership(address _promosOwner) external {
        require(
            msg.sender == promosOwner,
            "Promos: Caller is not the controller"
        );
        require(
            _promosOwner != address(0),
            "Promos: new controller is the zero address"
        );

        promosOwner = _promosOwner;
    }

    modifier MintPromos(address _to, uint256 _mintAmount) {
        address promosMintContract = PromosProxy(promosProxyContract)
            .promosMintAddress();
        require(_to != promosMintContract, "Not ERC721 reciever");
        require(msg.sender == promosMintContract, "Wrong msg.sender");
        require(_mintAmount <= promosSupply, "Exceeds Promos supply");
        promosSupply = promosSupply - _mintAmount;
        _;
    }

    function setPromosSupply(uint256 _promosSupply) external {
        require(msg.sender == promosOwner, "Promos: Caller is not the owner");
        promosSupply = _promosSupply;
    }

    function setPromosProxyContract(address _promosProxyContract) external {
        require(msg.sender == promosOwner, "Promos: Caller is not the owner");
        promosProxyContract = _promosProxyContract;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IPromos).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}