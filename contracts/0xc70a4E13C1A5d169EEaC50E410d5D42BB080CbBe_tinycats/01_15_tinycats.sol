//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./NonblockingReceiver.sol";

contract tinycats is ERC721, NonblockingReceiver {

    string public baseURI = "ipfs://QmWNnt3f2Ap6VuBFx5VZXAhBnREjQzpFfrSQaJeRDj8hFY/";
    string public contractURI = "ipfs://QmZTPht2Ud1mUZ3o5jzQhuaEYa37ufMZdJZWmZLCZfisMj";
    string public constant baseExtension = ".json";

    uint256 nextTokenId;
    uint256 MAX_MINT;

    uint256 gasForDestinationLzReceive = 350000;

    uint256 public constant MAX_PER_TX = 2;
    uint256 public constant MAX_PER_WALLET = 30;
    mapping(address => uint256) public minted;

    bool public paused = true;

    constructor(
        address _endpoint,
        uint256 startId,
        uint256 _max
    ) ERC721("tiny cats", "cat") {
        endpoint = ILayerZeroEndpoint(_endpoint);
        nextTokenId = startId;
        MAX_MINT = _max;
    }

    function mint(uint256 _amount) external payable {
        address _caller = _msgSender();
        require(!paused, "tiny cats: Paused");
        require(nextTokenId + _amount <= MAX_MINT, "tiny cats: Mint exceeds supply");
        require(MAX_PER_TX >= _amount , "tiny cats: Excess max per tx");
        require(MAX_PER_WALLET >= minted[_caller] + _amount, "tiny cats: Excess max per wallet");
        minted[_caller] += _amount;

        for(uint256 i = 0; i < _amount; i++) {
            _safeMint(_caller, ++nextTokenId);
        }
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
        require(
            msg.sender == ownerOf(tokenId),
            "You must own the token to traverse"
        );
        require(
            trustedRemoteLookup[_chainId].length > 0,
            "This chain is currently unavailable for travel"
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
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "tiny cats: msg.value not enough to cover messageFee. Send gas for message fees"
        );

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    function getEstimatedFees(uint16 _chainId, uint256 tokenId) public view returns (uint) {
        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);
        (uint quotedLayerZeroFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        return quotedLayerZeroFee;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              baseExtension
            )
        ) : "";
    }

    function setGasForDestinationLzReceive(uint256 _gasForDestinationLzReceive) external onlyOwner {
        gasForDestinationLzReceive = _gasForDestinationLzReceive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = _msgSender().call{value: balance}("");
        require(success, "Failed to send");
    }

    // ------------------
    // Internal Functions
    // ------------------

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

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }

}