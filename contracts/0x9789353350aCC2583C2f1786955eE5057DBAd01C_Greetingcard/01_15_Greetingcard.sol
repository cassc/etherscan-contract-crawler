// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Greetingcard is ERC1155, ReentrancyGuard, Ownable {
    using Address for address;

    event MintBatch(address user, uint256[] ids, uint256[] amounts);
    event Mint(address user, uint256 id, uint256 amount);

    mapping(uint256 => mapping(address => bool)) public _mintedAddress;
    IERC721 private drugReceiptToken;

    string public name;
    uint256 public nowTokenId = 0;

    bytes32 public merkleRoot;

    enum State {
        Setup,
        NormalMint,
        whitelistMint,
        PublicMint,
        Finished
    }

    State private _state;

    constructor(address _drugReceiptToken)
        ERC1155("https://batcave.drx.store/drxgreetingcard/token/{}")
    {
        drugReceiptToken = IERC721(_drugReceiptToken);
        _state = State.Setup;
        name = "DrugReceipts: DRx Greeting Cards";
    }

    function setContractName(string memory _name) public onlyOwner {
        name = _name;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        merkleRoot = _root;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        _setURI(_tokenURI);
    }

    function getTokenURI(uint256 _id) public view returns (string memory) {
        string memory idToString = Strings.toString(_id);
        string memory uri = uri(_id);
        string memory tokenURI = string(abi.encodePacked(uri, idToString));
        return tokenURI;
    }

    function getClaimStatus(uint256 _tokenId, address _address)
        public
        view
        returns (bool)
    {
        return _mintedAddress[_tokenId][_address];
    }

    function setStateToSetup() public onlyOwner {
        _state = State.Setup;
    }

    function setStateToNormalMint(uint256 _tokenId) public onlyOwner {
        _state = State.NormalMint;
        nowTokenId = _tokenId;
    }

    function setStateToWhitelistMint(uint256 _tokenId) public onlyOwner {
        _state = State.whitelistMint;
        nowTokenId = _tokenId;
    }

    function setStateToPublicMint() public onlyOwner {
        _state = State.PublicMint;
    }

    function setStateToFinished() public onlyOwner {
        _state = State.Finished;
    }

    function setRequiredToken(address _drugReceiptToken) external onlyOwner {
        drugReceiptToken = IERC721(_drugReceiptToken);
    }

    function normalMint() external nonReentrant {
        require(_state == State.NormalMint, "mint is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            drugReceiptToken.balanceOf(msg.sender) > 0,
            "You don't have any drug receipts"
        );

        require(
            _mintedAddress[nowTokenId][msg.sender] == false,
            "already minted with this address"
        );
        _mintedAddress[nowTokenId][msg.sender] = true;

        _mint(msg.sender, nowTokenId, 1, "");
        emit Mint(msg.sender, nowTokenId, 1);
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external nonReentrant {
        require(_state == State.whitelistMint, "mint is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            drugReceiptToken.balanceOf(msg.sender) > 0,
            "You don't have any drug receipts"
        );
        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof.");

        require(
            _mintedAddress[nowTokenId][msg.sender] == false,
            "already minted with this address"
        );
        _mintedAddress[nowTokenId][msg.sender] = true;

        _mint(msg.sender, nowTokenId, 1, "");
        emit Mint(msg.sender, nowTokenId, 1);
    }

    function publicMint(uint256 _tokenId) external nonReentrant {
        require(_state == State.PublicMint, "mint is not active");
        require(msg.sender == tx.origin, "mint from contract not allowed");
        require(
            !Address.isContract(msg.sender),
            "contracts are not allowed to mint"
        );
        require(
            drugReceiptToken.balanceOf(msg.sender) > 0,
            "You don't have any drug receipts"
        );

        require(
            _mintedAddress[_tokenId][msg.sender] == false,
            "already minted with this address"
        );
        _mintedAddress[_tokenId][msg.sender] = true;

        _mint(msg.sender, _tokenId, 1, "");
        emit Mint(msg.sender, _tokenId, 1);
    }

    function mintBatch(
        address _receiver,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyOwner {
        for (uint8 i = 0; i < ids.length; i++) {
            _mintedAddress[ids[i]][_receiver] = true;
        }
        _mintBatch(_receiver, ids, amounts, "");
        emit MintBatch(_receiver, ids, amounts);
    }

    function airdrop(
        address[] calldata wallets,
        uint256[][] memory ids,
        uint256[][] memory amounts
    ) external onlyOwner {
        unchecked {
            for (uint8 i = 0; i < wallets.length; i++) {
                for (uint8 j = 0; j < ids.length; j++) {
                    _mintedAddress[ids[i][j]][wallets[i]] = true;
                }
                _mintBatch(wallets[i], ids[i], amounts[i], "");
                emit MintBatch(wallets[i], ids[i], amounts[i]);
            }
        }
    }

    function withdrawAll(address recipient) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(recipient).transfer(balance);
    }

    function withdrawAllViaCall(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = _to.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function changeOwnership(address newOwner) public onlyOwner {
        transferOwnership(newOwner);
    }
}