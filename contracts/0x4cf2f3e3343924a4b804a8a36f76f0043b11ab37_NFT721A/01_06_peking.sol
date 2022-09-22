// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT721A is ERC721A, Ownable {
    using SafeMath for uint256;
    address public signer;
    address public passAddress;
    mapping(string => bool) internal nonceMap;
    mapping(uint256 => uint256) internal passMintMap;
    mapping(address => uint256) internal whiteListMintCountMap;
    mapping(address => uint256) internal publicMintCountMap;
    string public baseUri;
    uint256 public maxCount;
    bool passMintAvailable = false;
    bool whiteListMintAvailable = false;
    bool publicMintAvailable = false;
    uint256 public passMintPrice = 100000000000000000;
    uint256 public whiteListMintPrice = 100000000000000000;
    uint256 public publicMintPrice = 100000000000000000;
    uint256 public individualPassMintLimit = 2;
    uint256 public individualWhiteListMintLimit = 1;
    uint256 public individualPublicMintLimit = 5;

    constructor() ERC721A("Peking Monsters", "PEKING MONSTERS") {}

    event MintSuccess(address indexed operatorAddress, uint256 quantity, uint256 price, string nonce, uint256 blockHeight);

    //******SET UP******
    function setMaxCount(uint256 _maxCount) public onlyOwner {
        maxCount = _maxCount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseUri = _newURI;
    }

    function setPassAddress(address _passAddress) public onlyOwner {
        passAddress = _passAddress;
    }

    function setPassMintAvailable(bool _passMintAvailable) public onlyOwner {
        passMintAvailable = _passMintAvailable;
    }

    function setWhiteListMintAvailable(bool _whiteListMintAvailable) public onlyOwner {
        whiteListMintAvailable = _whiteListMintAvailable;
    }

    function setPublicMintAvailable(bool _publicMintAvailable) public onlyOwner {
        publicMintAvailable = _publicMintAvailable;
    }

    function setPassMintPrice(uint256 _passMintPrice) public onlyOwner {
        passMintPrice = _passMintPrice;
    }

    function setWhiteListMintPrice(uint256 _whiteListMintPrice) public onlyOwner {
        whiteListMintPrice = _whiteListMintPrice;
    }

    function setPublicMintPrice(uint256 _publicMintPrice) public onlyOwner {
        publicMintPrice = _publicMintPrice;
    }

    function setIndividualPassMintLimit(uint256 _individualPassMintLimit) public onlyOwner {
        individualPassMintLimit = _individualPassMintLimit;
    }

    function setIndividualWhiteListMintLimit(uint256 _individualWhiteListMintLimit) public onlyOwner {
        individualWhiteListMintLimit = _individualWhiteListMintLimit;
    }

    function setIndividualPublicMintLimit(uint256 _individualPublicMintLimit) public onlyOwner {
        individualPublicMintLimit = _individualPublicMintLimit;
    }
    //******END SET UP******

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function withdrawAll() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw(uint256 amount) public payable onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function passMintCount(uint256 passId) external view returns (uint256){
        return passMintMap[passId];
    }

    function passMint(
        uint256 quantity,
        uint256 passId,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(passMintAvailable, "Mint not available!");
        require(quantity > 0, "The quantity must more than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            passMintMap[passId] + quantity <= individualPassMintLimit,
            "You have reached individual safe mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashPassMint(quantity, passId, blockHeight, nonce, "peking_monsters_pass_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");
        IERC721A passContract = IERC721A(passAddress);
        require(passContract.ownerOf(passId) == msg.sender, "Invalid pass owner!");

        uint256 totalPrice = quantity.mul(passMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        nonceMap[nonce] = true;
        passMintMap[passId] = passMintMap[passId] + quantity;

        emit MintSuccess(msg.sender, quantity, totalPrice, nonce, blockHeight);
    }

    function whiteListMint(
        uint256 quantity,
        bytes32 hash,
        bytes memory signature,
        uint256 blockHeight,
        string memory nonce
    ) external payable {
        require(whiteListMintAvailable, "White list mint not available!");
        require(quantity > 0, "The quantity must more than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            whiteListMintCountMap[msg.sender] + quantity <= individualWhiteListMintLimit,
            "You have reached individual white list mint limit!"
        );
        //require(blockHeight >= block.number, "The block has expired!");
        require(!nonceMap[nonce], "Nonce already exist!");
        require(hashMint(quantity, blockHeight, nonce, "peking_monsters_white_list_mint") == hash, "Invalid hash!");
        require(matchAddressSigner(hash, signature), "Invalid signature!");

        uint256 totalPrice = quantity.mul(whiteListMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        nonceMap[nonce] = true;
        whiteListMintCountMap[msg.sender] = whiteListMintCountMap[msg.sender] + quantity;

        emit MintSuccess(msg.sender, quantity, totalPrice, nonce, blockHeight);
    }

    function mint(uint256 quantity) external payable {
        require(publicMintAvailable, "Mint not available!");
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "Not enough stock!"
        );
        require(
            publicMintCountMap[msg.sender] + quantity <= individualPublicMintLimit,
            "You have reached individual mint limit!"
        );

        uint256 totalPrice = quantity.mul(publicMintPrice);
        require(msg.value >= totalPrice, "Not enough money!");
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        _safeMint(msg.sender, quantity);
        publicMintCountMap[msg.sender] = publicMintCountMap[msg.sender] + quantity;

        emit MintSuccess(msg.sender, quantity, totalPrice, "", 0);
    }

    function airdrop(address to, uint256 quantity) public onlyOwner {
        require(quantity > 0, "The quantity is less than 0!");
        require(
            _nextTokenId() + quantity <= maxCount,
            "The quantity exceeds the stock!"
        );
        _safeMint(to, quantity);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function hashPassMint(uint256 quantity, uint256 passId, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, quantity, passId, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function hashMint(uint256 quantity, uint256 blockHeight, string memory nonce, string memory code)
    private
    view
    returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(msg.sender, quantity, blockHeight, nonce, code)
                )
            )
        );
        return hash;
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature)
    internal
    view
    returns (bool)
    {
        return signer == recoverSigner(hash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (
        bytes32 r,
        bytes32 s,
        uint8 v
    )
    {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}