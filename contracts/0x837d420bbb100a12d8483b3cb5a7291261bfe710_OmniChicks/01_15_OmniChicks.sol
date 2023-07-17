//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

abstract contract NonblockingReceiver is Ownable, ILayerZeroReceiver {
    ILayerZeroEndpoint internal endpoint;

    struct FailedMessages {
        uint256 payloadLength;
        bytes32 payloadHash;
    }

    mapping(uint16 => mapping(bytes => mapping(uint256 => FailedMessages)))
        public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        require(msg.sender == address(endpoint)); // boilerplate! lzReceive must be called by the endpoint for security
        require(
            _srcAddress.length == trustedRemoteLookup[_srcChainId].length &&
                keccak256(_srcAddress) ==
                keccak256(trustedRemoteLookup[_srcChainId]),
            "NonblockingReceiver: invalid source sending contract"
        );

        // try-catch all errors/exceptions
        // having failed messages does not block messages passing
        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(
                _payload.length,
                keccak256(_payload)
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public {
        // only internal transaction
        require(
            msg.sender == address(this),
            "NonblockingReceiver: caller must be Bridge."
        );

        // handle incoming message
        _LzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function
    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _txParam
    ) internal {
        endpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _txParam
        );
    }

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable {
        // assert there is message to retry
        FailedMessages storage failedMsg = failedMessages[_srcChainId][
            _srcAddress
        ][_nonce];
        require(
            failedMsg.payloadHash != bytes32(0),
            "NonblockingReceiver: no stored message"
        );
        require(
            _payload.length == failedMsg.payloadLength &&
                keccak256(_payload) == failedMsg.payloadHash,
            "LayerZero: invalid payload"
        );
        // clear the stored message
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote)
        external
        onlyOwner
    {
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }
}

contract OmniChicks is ERC721, Ownable, NonblockingReceiver {
   
    event ReceiveNFT(
        uint16 _srcChainId,
        bytes _from,
        uint256 _tokenId,
        address _to
    );

    event MessageFee(uint fee);

    using Strings for uint256;

    uint public nextId;
    uint public counter;
    uint public gasForDestinationLzReceive = 350000;
    uint public immutable UPPER_BOUND;
    uint public immutable MINT_PRICE;
    uint public constant FREE_CHICKS = 2;
    string public constant placeholderURL = "ipfs://QmQEWrvZsES7pqQ8fLgZbNR4VZD29w1RFiZd3cMPaT3mkL";
    // address immutable beneficiary;
    string private baseURL;
    bool revealFinalized = false;
    bool paused = true;

    mapping(address => uint) private _mintedCount;

    constructor(
        address endpoint_,
        uint startId_,
        uint mintPrice_,
        uint upperBound_
        // address beneficiary_
    ) 
    ERC721("OmniChicks", "OCC")
    {
        endpoint = ILayerZeroEndpoint(endpoint_);
        nextId = startId_;
        MINT_PRICE = mintPrice_;
        UPPER_BOUND = upperBound_;
        // beneficiary = beneficiary_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURL;
    }

    function totalSupply() external view returns (uint) {
        return nextId;
    }

    function finalizeReveal() external onlyOwner {
        revealFinalized = true;
    }

    function setPauseState(bool state) external onlyOwner {
        paused = state;
    }

    function reveal(string memory url) external onlyOwner {
        require(!revealFinalized, "Metadata is finalized");
        baseURL = url;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"))
            : placeholderURL;
    }

    function mint(uint count) external payable {
        require(nextId + count <= UPPER_BOUND, "Omnichicks: Can't fit any more chickens on this roost");
        require(!paused, "Mint is on pause");

        uint payForCount = count;
        uint mintedSoFar = _mintedCount[msg.sender];
        if(mintedSoFar < FREE_CHICKS) {
            uint remainingFreeChicks = FREE_CHICKS - mintedSoFar;
            if(count > remainingFreeChicks) {
                payForCount = count - remainingFreeChicks;
            }
            else {
                payForCount = 0;
            }
        }

        require(msg.value >= payForCount * MINT_PRICE, "Omnichicks: Needs more money");

        _mintedCount[msg.sender] += count;
        _mintTokens(msg.sender, count);
    }

    function mintedCount(address wallet) external view returns (uint) {
        return _mintedCount[wallet];
    }

    function _mintTokens(address to, uint count) internal {
        for(uint index = 0; index < count; index++) {
            nextId += 1;
            _safeMint(to, nextId);
        }
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Omnichicks: No balance");

        payable(owner()).transfer(balance);
    }

    function setTrustedRemotes(uint16[] calldata chainIds, bytes[] calldata addresses) external onlyOwner {
        for(uint i = 0; i < chainIds.length; i++) {
            trustedRemoteLookup[chainIds[i]] = addresses[i];
        }
    }

    function traverseChain(uint16 chainId_, uint tokenId) external payable {
        require(
            msg.sender == ownerOf(tokenId),
            "Omnichicks: You must own this chicken to traverse"
        );
        require(
            trustedRemoteLookup[chainId_].length != 0,
            "Omnichicks: This chain is currently unavailable for travel"
        );
        require(
            chainId_ != block.chainid,
            "Omnichicks: Destination blockhain can't be the same as source"
        );

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            chainId_,
            address(this),
            payload,
            false,
            // bytes("")
            adapterParams
        );

        emit MessageFee(messageFee);

        require(
            msg.value >= messageFee,
            "Omnichicks: value sent is not enough to cover messageFee. Increase gas for message fees"
        );

        endpoint.send{value: msg.value}(
            chainId_, // destination chainId
            trustedRemoteLookup[chainId_], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // future use
            // bytes("")
            adapterParams // txParameters
        );
    }

    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        // decode
        (address toAddr, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        emit ReceiveNFT(
            _srcChainId,
            _srcAddress,
            tokenId,
            toAddr
        );

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }
}