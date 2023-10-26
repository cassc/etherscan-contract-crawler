pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../LayerZero/NonblockingReceiver.sol';
import 'erc721a/contracts/ERC721A.sol';

contract LayerZeroERC721 is Ownable, ERC721A, NonblockingReceiver {
    address public _owner;
    string private baseURI;
    uint256 startId = 0;
    uint256 public MAX_MINT;
    uint256 public mintPerWallet;
    mapping(address => uint256) public giveawayAddresses;
    uint256 public reservedAmount = 0;
    uint256 public startTimestamp;

    uint256 gasForDestinationLzReceive = 350000;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _nextTokenId,
        uint256 _maxMint,
        uint256 _mintPerWallet,
        string memory baseURI_,
        address _layerZeroEndpoint,
        uint256 _startTimestamp
    ) ERC721A(_name, _symbol) {
        _owner = msg.sender;
        endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
        baseURI = baseURI_;
        MAX_MINT = _maxMint;
        mintPerWallet = _mintPerWallet;

        //Overrides currentIndex set from ERC721A constructor
        _currentIndex = _nextTokenId;
        startId = _nextTokenId;
        startTimestamp = _startTimestamp;
    }

    function _startTokenId() internal view override returns (uint256) {
        return startId;
    }

    // mint function
    // you can choose to mint 1 or 2
    // mint is free, but payments are accepted
    function mint(uint8 numTokens) external payable {
        require(block.timestamp >= startTimestamp, 'Not live');
        require(balanceOf(msg.sender) + numTokens <= mintPerWallet, 'Exceeds max NFTs per wallet');
        require(_currentIndex + numTokens + reservedAmount <= MAX_MINT, 'Mint exceeds supply');
        _safeMint(msg.sender, numTokens);
    }

    function mintGiveaway() external {
        require(block.timestamp >= startTimestamp, 'Not live');
        uint256 count = giveawayAddresses[msg.sender];
        require(count > 0, 'You dont have any giveaway mints');
        require(_currentIndex + count <= MAX_MINT, 'Mint exceeds supply');
        delete giveawayAddresses[msg.sender];
        reservedAmount -= count;
        _safeMint(msg.sender, count);
    }

    function setGiveawayAddresses(address[] memory addresses, uint256[] memory counts) external onlyOwner {
        require(addresses.length == counts.length, 'addresses does not match numSlots length');
        for (uint256 i = 0; i < addresses.length; i++) {
            reservedAmount += counts[i];
            giveawayAddresses[addresses[i]] = counts[i];
        }
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), 'You must own the token to traverse');
        require(trustedRemoteLookup[_chainId].length > 0, 'This chain is currently unavailable for travel');

        // burn NFT, eliminating it from circulation on src chain
        _burn(tokenId);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);

        require(msg.value >= messageFee, 'msg.value not enough to cover messageFee. Send gas for message fees');

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            trustedRemoteLookup[_chainId], // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    function setBaseURI(string memory URI) external onlyOwner {
        baseURI = URI;
    }

    function setNextTokenId(uint256 _nextTokenId) external onlyOwner {
        _currentIndex = _nextTokenId;
    }

    function setMaxMint(uint256 _MAX_MINT) external onlyOwner {
        MAX_MINT = _MAX_MINT;
    }

    function estimateFees(uint16 _chainId, uint256 tokenId) public view returns (uint256) {
        uint16 version = 1;
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            abi.encode(msg.sender, tokenId),
            false,
            abi.encodePacked(version, gasForDestinationLzReceive)
        );

        return messageFee;
    }

    function donate() external payable {
        // thank you
    }

    // This allows the devs to receive kind donations
    function withdraw(uint256 amt) external onlyOwner {
        (bool sent, ) = payable(_owner).call{value: amt}('');
        require(sent, 'Failed to withdraw Ether');
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }

    function maxMint() external view returns (uint256) {
        return MAX_MINT - startId;
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
        (address toAddr, uint256 tokenId) = abi.decode(_payload, (address, uint256));

        // mint the tokens back into existence on destination chain
        _safeMint(toAddr, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}