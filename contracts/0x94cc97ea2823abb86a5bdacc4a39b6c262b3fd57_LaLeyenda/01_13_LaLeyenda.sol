// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "openzeppelin-contracts/token/ERC1155/ERC1155.sol";

contract LaLeyenda is ERC1155, Ownable {
    uint256 public numTokens = 0;
    string public name = "LaLeyenda";
    string public symbol = "LAL";
    address public crossmintAddress =
        0xdAb1a1854214684acE522439684a145E62505233;

    mapping(uint256 => Token) public tokens;

    event Crossmint(
        address indexed to,
        uint256 indexed tokenId,
        uint256 amount
    );
    event Mint(address indexed to, uint256 indexed tokenId, uint256 amount);

    struct Token {
        uint256 publicPrice;
        uint256 allowlistPrice;
        uint256 totalSupply;
        uint256 minted;
        uint256 startTime;
        uint256 endTime;
        string uri;
        bytes32 merkleRoot;
    }

    constructor() ERC1155("") {}

    function _leaf(string memory tokenId, string memory payload)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, tokenId));
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    function mint(
        uint256 tokenId,
        uint256 count,
        bytes32[] calldata proof
    ) external payable {
        require(tokenId <= numTokens, "invalid token id");

        if (msg.sender != owner()) {
            string memory payload = string(abi.encodePacked(msg.sender));

            uint256 price = tokens[tokenId].allowlistPrice;

            if (proof.length == 0) {
                price = tokens[tokenId].publicPrice;
            } else {
                require(
                    MerkleProof.verify(
                        proof,
                        tokens[tokenId].merkleRoot,
                        _leaf(Strings.toString(tokenId), payload)
                    ),
                    "invalid proof"
                );
            }

            require(
                block.timestamp > tokens[tokenId].startTime &&
                    block.timestamp < tokens[tokenId].endTime,
                "token not active"
            );
            if (tokens[tokenId].totalSupply > 0) {
                require(
                    tokens[tokenId].minted + count <=
                        tokens[tokenId].totalSupply,
                    "exceeds total supply"
                );
            }
            require(count * price == msg.value, "invalid value");
        }

        tokens[tokenId].minted += count;
        _mint(msg.sender, tokenId, count, "");

        emit Mint(msg.sender, tokenId, count);
    }

    function crossmint(
        address to,
        uint256 tokenId,
        uint256 count
    ) public payable {
        require(tokenId <= numTokens, "invalid token id");
        require(
            msg.value >= tokens[tokenId].publicPrice * count,
            "invalid value"
        );
        require(
            tokens[tokenId].minted + count <= tokens[tokenId].totalSupply,
            "exceeds total supply"
        );
        require(
            msg.sender == crossmintAddress,
            "this function is for crossmint only"
        );
        require(
            block.timestamp > tokens[tokenId].startTime &&
                block.timestamp < tokens[tokenId].endTime,
            "token not active"
        );

        tokens[tokenId].minted += count;
        _mint(to, tokenId, count, "");

        emit Crossmint(to, tokenId, count);
    }

    function addToken(
        uint256 _publicPrice,
        uint256 _allowlistPrice,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[numTokens];
        token.publicPrice = _publicPrice;
        token.allowlistPrice = _allowlistPrice;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;

        numTokens += 1;
    }

    function editToken(
        uint256 tokenId,
        uint256 _publicPrice,
        uint256 _allowlistPrice,
        uint256 _totalSupply,
        uint256 _startTime,
        uint256 _endTime,
        string memory _uri,
        bytes32 _merkleRoot
    ) public onlyOwner {
        Token storage token = tokens[tokenId];
        token.publicPrice = _publicPrice;
        token.allowlistPrice = _allowlistPrice;
        token.totalSupply = _totalSupply;
        token.startTime = _startTime;
        token.endTime = _endTime;
        token.uri = _uri;
        token.merkleRoot = _merkleRoot;
    }

    function editAllowlist(uint256 tokenId, bytes32 _merkleRoot)
        public
        onlyOwner
    {
        tokens[tokenId].merkleRoot = _merkleRoot;
    }

    function editPublicPrice(uint256 tokenId, uint256 _publicPrice)
        public
        onlyOwner
    {
        tokens[tokenId].publicPrice = _publicPrice;
    }

    function editAllowlistPrice(uint256 tokenId, uint256 _allowlistPrice)
        public
        onlyOwner
    {
        tokens[tokenId].allowlistPrice = _allowlistPrice;
    }

    function editTotalSupply(uint256 tokenId, uint256 _totalSupply)
        public
        onlyOwner
    {
        tokens[tokenId].totalSupply = _totalSupply;
    }

    function editStartTime(uint256 tokenId, uint256 _startTime)
        public
        onlyOwner
    {
        tokens[tokenId].startTime = _startTime;
    }

    function editEndTime(uint256 tokenId, uint256 _endTime) public onlyOwner {
        tokens[tokenId].endTime = _endTime;
    }

    function editUri(uint256 tokenId, string memory _uri) public onlyOwner {
        tokens[tokenId].uri = _uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "failed to receive ether");
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokens[tokenId].uri;
    }
}