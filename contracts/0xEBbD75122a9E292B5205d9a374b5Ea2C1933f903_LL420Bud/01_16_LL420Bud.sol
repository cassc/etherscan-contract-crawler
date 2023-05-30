//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Bud
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/ILL420GameKey.sol";
import "./interfaces/ILL420GreenPass.sol";

contract LL420Bud is Ownable, ERC721A, ReentrancyGuard, Pausable {
    uint8 public constant OG_MAX_PASSES = 2;
    uint8 public constant NON_OG_MAX_PASSES = 1;
    uint8 public constant PUBLIC_MAX_PASSES = 3;

    // TODO: Check intervals and supplies on mainnet
    uint256 public constant OG_TIME_LIMIT = 24 hours; // 24 hours
    uint256 public constant TIME_WINDOW = 24 hours; // 24 hours
    uint256 public constant TOTAL_SUPPLY = 20000; // 20000
    uint256 public constant FREE_MINT_SUPPLY = 10000; // 10000
    uint256 public constant BUDS_PRICE = 0.042 ether;
    uint256 public constant OG_PASS_TOKEN_ID = 1;

    address public GAMEKEY_CONTRACT;
    address public constant GREENPASS_CONTRACT = 0xFe190723a465C99293c4f035045C0a6880D25DbE;

    mapping(uint256 => bool) public isGameKeyUsed;

    address public VAULT;
    uint256 public startTimestamp;
    uint256 public freeMintCount;

    string private _baseTokenURI;

    event MintBudWithGameKey(address indexed _user, uint256 indexed _id);
    event PublicMint(address indexed _user, uint256 _quantity);

    constructor(
        address _gpContract,
        address _gkContract,
        uint256 _startTimestamp,
        string memory _baseuri
    ) ERC721A("LOOK LABS 420 Buds", "BUDS") {
        // GREENPASS_CONTRACT = _gpContract;
        GAMEKEY_CONTRACT = _gkContract;
        startTimestamp = _startTimestamp;
        _baseTokenURI = _baseuri;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "LL420Bud: The caller is another contract");
        _;
    }

    modifier onlyStarted() {
        require(block.timestamp >= startTimestamp, "LL420Bud: Not started yet");
        _;
    }

    function freeMint(address _to, uint256 _quantity) external onlyStarted whenNotPaused {
        require(_to != address(0), "LL420Bud: Incorrect address");
        require(_quantity > 0 && freeMintCount + _quantity <= FREE_MINT_SUPPLY, "LL420Bud: Reached max free supply");
        require(GAMEKEY_CONTRACT != address(0) && msg.sender == GAMEKEY_CONTRACT, "LL420Bud: Not allowed caller");

        freeMintCount += _quantity;
        _safeMint(_to, _quantity);
    }

    function saleMint(uint256 _quantity, uint256[] memory _gkIds)
        external
        payable
        nonReentrant
        callerIsUser
        onlyStarted
        whenNotPaused
    {
        uint256 gameKeyBalance = getGameKeyBalanace(msg.sender);
        uint256 nonFreeMintCount = _totalMinted() - freeMintCount;

        require(gameKeyBalance > 0, "LL420Bud: Need a game key");
        require(
            _quantity > 0 && nonFreeMintCount + _quantity <= TOTAL_SUPPLY - FREE_MINT_SUPPLY,
            "LL420Bud: Reached max supply"
        );

        uint256 timePeriod = block.timestamp - startTimestamp;

        if (timePeriod > OG_TIME_LIMIT + TIME_WINDOW) {
            // Public mint
            require(_quantity <= PUBLIC_MAX_PASSES, "LL420Bud: Surpassed quantity limit");

            emit PublicMint(msg.sender, _quantity);
        } else {
            require(
                gameKeyBalance == _gkIds.length && verifyGameKeyOwnership(_gkIds),
                "LL420Bud: Incorrect game key holdings"
            );
            require(checkGameKeyUsed(_gkIds) == false, "LL420Bud: Used game keys");

            if (timePeriod <= OG_TIME_LIMIT) {
                // Time for OG holder
                require(_quantity <= gameKeyBalance * OG_MAX_PASSES, "LL420Bud: Surpassed quantity limit");
                require(isOGPassHolder(msg.sender), "LL420Bud: Not an OG");
            } else if (timePeriod <= OG_TIME_LIMIT + TIME_WINDOW) {
                // Time for non-OG holder
                require(_quantity <= gameKeyBalance * NON_OG_MAX_PASSES, "LL420Bud: Surpassed quantity limit");
            } else {
                revert("LL420Bud: Unexpected case");
            }

            for (uint256 index = 0; index < _gkIds.length; index++) {
                isGameKeyUsed[_gkIds[index]] = true;

                emit MintBudWithGameKey(msg.sender, _gkIds[index]);
            }
        }

        refundIfOver(BUDS_PRICE * _quantity);
        _safeMint(msg.sender, _quantity);
    }

    function verifyGameKeyOwnership(uint256[] memory _ids) private view returns (bool) {
        require(GAMEKEY_CONTRACT != address(0), "LL420Bud: Missing game key address");
        ILL420GameKey gkContract = ILL420GameKey(GAMEKEY_CONTRACT);

        return gkContract.verifyOwnershipBatch(msg.sender, _ids);
    }

    function checkGameKeyUsed(uint256[] memory _ids) private view returns (bool) {
        for (uint256 index = 0; index < _ids.length; index++) {
            if (isGameKeyUsed[_ids[index]] == true) {
                return true;
            }
        }

        return false;
    }

    function getGameKeyBalanace(address _user) private view returns (uint256) {
        require(GAMEKEY_CONTRACT != address(0), "LL420Bud: Missing game key address");

        return ILL420GameKey(GAMEKEY_CONTRACT).balanceOf(_user);
    }

    function isOGPassHolder(address _user) private view returns (bool) {
        return ILL420GreenPass(GREENPASS_CONTRACT).balanceOf(_user, OG_PASS_TOKEN_ID) > 0;
    }

    function refundIfOver(uint256 _price) private {
        require(_price >= 0 && msg.value >= _price, "LL420Bud: Need to send more ETH");
        if (msg.value > _price) {
            payable(msg.sender).transfer(msg.value - _price);
        }
    }

    function numberMinted(address _owner) external view returns (uint256) {
        return _numberMinted(_owner);
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Owner functions
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAll() external onlyOwner {
        (bool success, ) = payable(VAULT).call{ value: address(this).balance }("");

        require(success, "LL420Bud: Failed to withdraw to VAULT");
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(address(VAULT) != address(0), "LL420Bud: No vault");
        require(payable(VAULT).send(_amount), "LL420Bud: Withdraw failed");
    }

    function setVault(address _newVaultAddress) external onlyOwner {
        VAULT = _newVaultAddress;
    }

    function setGameKeyContract(address _gameKeyContractAddress) external onlyOwner {
        GAMEKEY_CONTRACT = _gameKeyContractAddress;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function vaultMint(uint256 _quantity) external onlyOwner onlyStarted {
        require(_totalMinted() + _quantity <= TOTAL_SUPPLY, "LL420Bud: Reached the max supply");

        _mint(msg.sender, _quantity, "", false);
    }
}