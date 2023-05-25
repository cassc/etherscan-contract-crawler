//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

contract RayGuns is ERC721A, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using Address for address;

    string public _tokenUriBase;
    uint256 public mintPrice;

    bytes32 private merkleRoot;
    address private signer;
    State private _state;

    mapping(address => bool) public claimed;
    mapping(bytes => bool) public usedToken;

    enum State {
        StageOne,
        StageTwo,
        Closed
    }

    uint256 public stageOneSupply = 3003;
    uint256 public stageTwoSupply = 5005;

    event Minted(address account, uint256 amount);

    constructor(
        address _signer,
        bytes32 _merkleRoot,
        uint256 _mintPrice
    ) ERC721A("Dr. Grordborts: Rayguns", "RAYGUNS") {
        signer = _signer;
        merkleRoot = _merkleRoot;
        mintPrice = _mintPrice;
        _state = State.Closed;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setStageOneOpen() external onlyOwner {
        _state = State.StageOne;
    }

    function setStageTwoOpen() external onlyOwner {
        _state = State.StageTwo;
    }

    function setClosed() external onlyOwner {
        _state = State.Closed;
    }

    function setStageOneSupply(uint256 _supply) external onlyOwner {
        stageOneSupply = _supply;
    }

    function setStageTwoSupply(uint256 _supply) external onlyOwner {
        stageTwoSupply = _supply;
    }

    function adminMint(uint256 amount, address _to) external onlyOwner {
        _safeMint(_to, amount);
    }

    function mintToOwner(
        address[] calldata _contractAddresses,
        uint256[] calldata _tokenIds
    ) external onlyOwner {
        require(
            _contractAddresses.length == _tokenIds.length,
            "array must be equal length"
        );
        for (uint256 i = 0; i < _contractAddresses.length; i++) {
            address owner = IERC721(_contractAddresses[i]).ownerOf(
                _tokenIds[i]
            );
            _safeMint(owner, 1);
            emit Minted(owner, 1);
        }
    }

    function mintStageOne(bytes32[] calldata proof, bytes memory data)
        external
        nonReentrant
    {
        require(_state == State.StageOne, "claim has not started yet");
        require(msg.sender == tx.origin, "contracts cant mint");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(claimed[msg.sender] == false, "already minted");
        (address _address, uint256 _amount) = abi.decode(
            data,
            (address, uint256)
        );
        require(_amount <= 6, "max array length reached");
        require(
            totalSupply() + _amount <= stageOneSupply,
            "stage one has reached max supply"
        );
        require(_address == msg.sender, "not encoded for you");
        require(
            MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, _amount))
            ),
            "Invalid merkle proof"
        );
        claimed[msg.sender] = true;
        _safeMint(msg.sender, _amount);
        emit Minted(msg.sender, _amount);
    }

    function mintStageTwo(
        string calldata salt,
        bytes calldata token,
        uint16 amount
    ) external payable nonReentrant {
        require(_state == State.StageTwo, "claim has not started yet");
        require(
            totalSupply() + amount <= stageTwoSupply,
            "stage two has reached max supply"
        );
        require(msg.value >= mintPrice, "invalid ether sent");
        require(msg.sender == tx.origin, "contracts cant mint");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(amount <= 6, "You can only mint 6 rayguns at a time.");
        require(!usedToken[token], "The token has been used.");
        require(_verify(_hash(salt, msg.sender), token), "Invalid token.");
        _safeMint(msg.sender, amount);
        usedToken[token] = true;
        emit Minted(msg.sender, amount);
    }

    function _hash(string calldata salt, address _address)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address));
    }

    function _recover(bytes32 hash, bytes memory token)
        public
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function _verify(bytes32 hash, bytes memory token)
        public
        view
        returns (bool)
    {
        return (_recover(hash, token) == signer);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
            string(abi.encodePacked(_tokenUriBase, Strings.toString(tokenId)));
    }

    function setTokenURI(string memory tokenUriBase_) public onlyOwner {
        _tokenUriBase = tokenUriBase_;
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }
}