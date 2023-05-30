// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC173.sol";
import "./MooarNFTHelper.sol";
import "./TransferHelper.sol";

contract MooarNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    string private _baseTokenURI;
    address private _mooar;
    string private _tokenSuffix;

    uint256 public maxSupply;
    uint256 public ethMintCost;
    address public tokenMintBaseToken;
    uint256 public tokenMintCost;
    MooarNFTLaunchStatus public launchStatus;
    
    mapping(address => bool) private _priorityMinterRecords;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        string memory tokenSuffix,
        uint256 maxSupply_,
        uint256 ethMintCost_,
        address tokenMintBaseToken_,
        uint256 tokenMintCost_)
        ERC721(name, symbol)
    {
        _baseTokenURI = baseURI;
        _mooar = _msgSender();
        _tokenSuffix = tokenSuffix;

        maxSupply = maxSupply_;
        ethMintCost = ethMintCost_;
        tokenMintBaseToken = tokenMintBaseToken_;
        tokenMintCost = tokenMintCost_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC173).interfaceId || super.supportsInterface(interfaceId);
    }

    modifier onlyMooar() {
        require(_msgSender() == _mooar, "Only for mooar contract");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory uri = super.tokenURI(tokenId);
        return bytes(_tokenSuffix).length > 0 ? string(abi.encodePacked(uri, _tokenSuffix)) : uri;
    }

    function setMooarLaunch(bytes32 tokenMerkleRoot, uint256 redeemMintStartTime, uint256 unfreezeMintStartTime) external onlyMooar {
        launchStatus.isMooarLaunched = true;
        launchStatus.tokenMerkleRoot = tokenMerkleRoot;
        launchStatus.redeemMintStartTime = redeemMintStartTime;
        launchStatus.unfreezeMintStartTime = unfreezeMintStartTime;
    }

    function setMooarUnlaunch(bytes32 priorityMerkleRoot, uint256 priorityMintStartTime, uint256 directMintStartTime) external onlyMooar {
        launchStatus.isMooarUnlaunched = true;
        launchStatus.priorityMerkleRoot = priorityMerkleRoot;
        launchStatus.priorityMintStartTime = priorityMintStartTime;
        launchStatus.directMintStartTime = directMintStartTime;
    }

    function redeemMint(uint256 tokenId, bytes32[] calldata proof) external nonReentrant {
        address account = _msgSender();
        MooarNFTHelper.verifyRedeemMint(account, launchStatus, tokenId, proof);
        _safeMint(account, tokenId);
    }

    function unfreezeMintByETH(uint256 tokenId, bytes32[] calldata proof) external nonReentrant payable {
        require(_exists(tokenId) == false, "Token minted");
   
        address account = _msgSender();
        MooarNFTHelper.verifyUnfreezeMintByETH(ethMintCost, launchStatus, tokenId, proof);
        _safeMint(account, tokenId);
    }

    function unfreezeMintByToken(uint256 tokenId, bytes32[] calldata proof) external nonReentrant {
        require(_exists(tokenId) == false, "Token minted");
   
        address account = _msgSender();
        MooarNFTHelper.verifyUnfreezeMintByToken(tokenMintBaseToken, tokenMintCost, launchStatus, tokenId, proof);

        TransferHelper.safeTransferFrom(
            tokenMintBaseToken,
            account,
            address(this),
            tokenMintCost
        );
        _safeMint(account, tokenId);
    }

    function priorityMintByETH(bytes32[] calldata proof) external nonReentrant payable {
        address account = _msgSender();
        require(totalSupply() < maxSupply, "Out of the max supply");
        require(_priorityMinterRecords[account] != true, "Has priority minted");
        _priorityMinterRecords[account] = true;

        MooarNFTHelper.verifyPriorityMintByETH(account, ethMintCost, launchStatus, proof);

        _safeMint(account, totalSupply());
    }

    function priorityMintByToken(bytes32[] calldata proof) external nonReentrant {
        address account = _msgSender();
        require(totalSupply() < maxSupply, "Out of the max supply");
        require(_priorityMinterRecords[account] != true, "Has priority minted");
        _priorityMinterRecords[account] = true;

        MooarNFTHelper.verifyPriorityMintByToken(account, tokenMintBaseToken, tokenMintCost, launchStatus, proof);

        TransferHelper.safeTransferFrom(
            tokenMintBaseToken,
            account,
            address(this),
            tokenMintCost
        );
        _safeMint(account, totalSupply());
    }

    function directMintByETH() external nonReentrant payable {
        require(totalSupply() < maxSupply, "Out of the max supply");
        MooarNFTHelper.verifyDirectMintByETH(ethMintCost, launchStatus);

        _safeMint(msg.sender, totalSupply());
    }

    function directMintByToken() external nonReentrant {
        require(totalSupply() < maxSupply, "Out of the max supply");
        MooarNFTHelper.verifyDirectMintByToken(tokenMintBaseToken, tokenMintCost, launchStatus);

        TransferHelper.safeTransferFrom(
            tokenMintBaseToken,
            msg.sender,
            address(this),
            tokenMintCost
        );
        _safeMint(msg.sender, totalSupply());
    }

    function burn(uint256 tokenId) external virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }

    function withdrawToken(address receiver, address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, receiver, amount);
    }

    function withdrawETH(address receiver, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(receiver, amount);
    }
}