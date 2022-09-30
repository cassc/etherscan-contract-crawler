pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Forwarder {
    using ECDSA for bytes32;

    struct CatalogRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        uint256 sigChainID;
        uint256 chainID;
        bytes data;
    }

    bytes32 private constant HASHED_NAME = keccak256(bytes("CatalogForworder"));
    bytes32 private constant HASHED_VERSION = keccak256(bytes("0.0.1"));
    bytes32 private constant TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant _TYPEHASH =
        keccak256(
            "CatalogRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint256 chainID,uint256 sigChainID,bytes data)"
        );

    mapping(address => uint256) private _nonces;

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function domainSeperator(uint256 _chainID) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    HASHED_NAME,
                    HASHED_VERSION,
                    _chainID,
                    address(this)
                )
            );
    }

    function verify(CatalogRequest calldata req, bytes calldata signature)
        public
        view
        returns (bool)
    {
        address signer = domainSeperator(req.sigChainID)
            .toTypedDataHash(
                keccak256(
                    abi.encode(
                        _TYPEHASH,
                        req.from,
                        req.to,
                        req.value,
                        req.gas,
                        req.nonce,
                        req.chainID,
                        req.sigChainID,
                        keccak256(req.data)
                    )
                )
            )
            .recover(signature);
        return
            block.chainid == req.chainID &&
            _nonces[req.from] == req.nonce &&
            signer == req.from;
    }

    function execute(CatalogRequest calldata req, bytes calldata signature)
        public
        payable
    {
        require(
            verify(req, signature),
            "MinimalForwarder: signature does not match request"
        );
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{
            gas: req.gas,
            value: req.value
        }(abi.encodePacked(req.data, req.from));
        require(success, string(returndata));

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        assert(gasleft() > req.gas / 63);
    }
}