// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "openzeppelin-solidity/contracts/access/AccessControl.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721Main.sol";
import "./exchange-provider/ExchangeProvider.sol";

contract FactoryErc721 is AccessControl, ExchangeProvider {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    string private CONTRACT_URI;

    uint256 private fee;
    address private receiver;

    event ERC721Made(
        address newToken,
        string name,
        string symbol,
        address indexed signer
    );

    constructor(address _exchange, string memory _CONTRACT_URI) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SIGNER_ROLE, _msgSender());
        exchange = _exchange;
        CONTRACT_URI = _CONTRACT_URI;
    }

    function makeERC721(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address signer,
        bytes memory signature
    ) external {
        _verifySigner(signer, signature);
        ERC721Main newAddress = new ERC721Main(name, symbol, baseURI, CONTRACT_URI, signer);

        emit ERC721Made(address(newAddress), name, symbol, signer);
    }

    function getFee() external view returns(uint256) {
        return fee;
    }

    function getReceiver() external view returns(address) {
        return receiver;
    }

    function setFee(uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = _fee;
    }

    function setReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        receiver = _receiver;
    }

    function _verifySigner(address signer, bytes memory signature)
        private
        view
    {
        address messageSigner =
            ECDSA.recover(keccak256(abi.encodePacked(signer)), signature);
        require(
            hasRole(SIGNER_ROLE, messageSigner),
            "FactoryErc721: Signer should sign transaction"
        );
    }
}