// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "../interfaces/IQredoWalletImplementation.sol";
import "../interfaces/IWalletFactory.sol";
import "../libraries/Create2.sol";

contract WalletFactory is IWalletFactory {

    mapping(address => address) private walletOwner;
    address immutable private _template;

    constructor(address _template_) public {
        require(_template_ != address(0), "WF::constructor:_template_ address cannot be 0");
        _template = _template_;
    }

    function computeFutureWalletAddress(address _walletOwner) external override view returns(address _walletAddress) {
        return Create2.computeAddress(
                    keccak256(abi.encodePacked(_walletOwner)),
                    keccak256(getBytecode())
                );
    }
   
    function createWallet(address _walletOwner) external override returns (address _walletAddress) {
        require(_walletOwner != address(0), "WF::createWallet:owner address cannot be 0");
        require(walletOwner[_walletOwner] == address(0), "WF::createWallet:owner already has wallet");
        address wallet = Create2.deploy(
                0,
                keccak256(abi.encodePacked(_walletOwner)),
                getBytecode()
            );
        IQredoWalletImplementation(wallet).init(_walletOwner);
        walletOwner[_walletOwner] = address(wallet);
        emit WalletCreated(msg.sender, address(wallet), _walletOwner);
        return wallet;
    }

    /**
      * @dev Returns template address of the current {owner};
    */
    function getWalletByOwner(address owner) external override view returns (address _wallet) {
        return walletOwner[owner];
    }

    function verifyWallet(address wallet) external override view returns (bool _validWallet) {
        return walletOwner[IQredoWalletImplementation(wallet).getWalletOwnerAddress()] != address(0);
    }

    /**
      * @dev Returns template address;
    */
    function getTemplate() external override view returns (address template){
        return _template;
    }

    /**
      * @dev EIP-1167 Minimal Proxy Bytecode with included Creation code.
      * More information on EIP-1167 Minimal Proxy and the full bytecode 
      * read more here: 
      * (https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract)
    */
    function getBytecode() private view returns (bytes memory) {
        bytes10 creation = 0x3d602d80600a3d3981f3;
        bytes10 runtimePrefix = 0x363d3d373d3d3d363d73;
        bytes20 targetBytes = bytes20(_template);
        bytes15 runtimeSuffix = 0x5af43d82803e903d91602b57fd5bf3;
        return abi.encodePacked(creation, runtimePrefix, targetBytes, runtimeSuffix);
    }
}