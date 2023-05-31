// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../ERC1155/IPass.sol";

contract Raffle is ERC721Enumerable, Ownable, ReentrancyGuard {
    
    uint256 constant MAX_SUPPLY = 10_000;
    uint256 constant RESERVED_TOKENS = 25;

    event TogglePaused(bool _pause);

    uint256 public waveType = 0;
    uint256 public waveMaxTokens;
    uint256 public waveMaxTokensToBuy;
    uint256 public waveSingleTokenPrice;
    uint256 public waveTotalMinted;
    uint256 public reservedClaimed;
    address public contractAddress;
    uint256 public erc1155Id;

    mapping(address => mapping(uint256 => uint256)) waveOwnerToClaimedCounts;
    uint256 public indexWave;
    uint256 public paused;

    mapping(uint256 => uint256) private signatureIds;
    mapping(uint256 => uint256) private availableIds;

    address public payoutToken;
    address payeeWallet;
    address public signAddress;
    string baseTokenURI;

    constructor(
        string memory baseURI,
        string memory _name,
        string memory _symbol,
        address payable _payeeWallet,
        address _payoutToken,
        address _signAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(baseURI);
        payeeWallet = _payeeWallet;
        payoutToken = _payoutToken;
        signAddress = _signAddress;
    }

    function setupWave(
        uint256 _waveType,
        uint256 _waveMaxTokens,
        uint256 _waveMaxTokensToBuy,
        uint256 _waveSingleTokenPrice,
        address _contractAddress,
        uint256 _erc1155Id
    ) external onlyOwner {
        require(_waveType < 2 && _waveMaxTokens > 0 && _waveMaxTokensToBuy > 0 && _waveMaxTokens + totalSupply() <= MAX_SUPPLY, "Invalid configuration");
        if (_waveType != 0) {
            require(_contractAddress != address(0x0), "Invalid contract address");
        }
        require(_waveMaxTokensToBuy <= _waveMaxTokens, "Invalid supply configuration");

        waveType = _waveType;
        waveMaxTokens = _waveMaxTokens;
        waveMaxTokensToBuy = _waveMaxTokensToBuy;
        waveSingleTokenPrice = _waveSingleTokenPrice;
        waveTotalMinted = 0;
        contractAddress = _waveType == 0 ? address(0) : _contractAddress;
        erc1155Id = _waveType == 1 ? _erc1155Id : 0;
        indexWave++;
    }

    function checkWaveNotComplete(uint256 _amount) internal view returns (bool) {
        return _amount > 0 && waveTotalMinted + _amount <= waveMaxTokens;
    }

    function checkLimitNotReached(address _wallet, uint256 _amount) internal view returns (bool) {
        return
            waveOwnerToClaimedCounts[_wallet][indexWave - 1] + _amount <= waveMaxTokensToBuy &&
            totalSupply() + _amount <= MAX_SUPPLY;
    }

    function checkMintAllowed(address _wallet, uint256 _amount) public view returns (bool) {
        return checkWaveNotComplete(_amount) && checkLimitNotReached(_wallet, _amount);
    }

    function waveClaimedCount(address _wallet) public view returns (uint256) {
        return waveOwnerToClaimedCounts[_wallet][indexWave - 1];
    }

    function claimReserved(address[] memory recipients) external onlyOwner {
        uint256 count = recipients.length;
        require(reservedClaimed + count <= RESERVED_TOKENS && reservedClaimed + count <= MAX_SUPPLY, "Minting will exceed supply");
        
        reservedClaimed += count;

        for (uint256 i = 0; i < count; i++) {
            randomMint(recipients[i]);
        }
    }

    function mint(
        uint256 _amount,
        uint256 _erc1155Id,
        uint256 _signatureId,
        bytes memory _signature
    ) external nonReentrant {
        require(indexWave > 0, "Contract is not configured");
        require(paused == 0, "Not in sale");
        require(signatureIds[_signatureId] == 0, "SignatureId already used");
        require(
            checkSignature(_msgSender(), _signatureId, address(this), block.chainid, _signature) == signAddress,
            "Signature failed"
        );

        signatureIds[_signatureId] = 1;

        require(checkWaveNotComplete(_amount), "Wave completed");
        require(checkLimitNotReached(_msgSender(), _amount), "Max allowed");

        if (waveType == 1) {
            require(_erc1155Id <= erc1155Id, "Minting pass is not applicable");
            IPass(contractAddress).redeem(_msgSender(), _erc1155Id, 1);
        }

        uint256 _price = waveSingleTokenPrice * _amount;
        if (_price > 0) {
            SafeERC20.safeTransferFrom(IERC20(payoutToken), _msgSender(), payeeWallet, _price);
        }

        waveOwnerToClaimedCounts[_msgSender()][indexWave - 1] += _amount;

        waveTotalMinted += _amount;

        for (uint256 i = 0; i < _amount; i++) {
            randomMint(_msgSender());
        }
    }

    function randomMint(address to) internal{
        uint256 tokenId = getRandomToken(to, totalSupply());
        _safeMint(to, tokenId);
    }

    function checkSignature(
        address _wallet,
        uint256 _signatureId,
        address _contractAddress,
        uint256 _chainId,
        bytes memory _signature
    ) public pure returns (address) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        keccak256(abi.encode(_wallet, _signatureId, _contractAddress, _chainId))
                    )
                ),
                _signature
            );
    }

    function getRandomToken(address _wallet, uint256 _totalMinted) private returns (uint256) {
        uint256 remaining = MAX_SUPPLY - _totalMinted;
        uint256 rand =
            uint256(keccak256(abi.encodePacked(_wallet, block.difficulty, block.timestamp, remaining))) % remaining;
        uint256 value = rand;

        if (availableIds[rand] != 0) {
            value = availableIds[rand];
        }

        if (availableIds[remaining - 1] == 0) {
            availableIds[rand] = remaining - 1;
        } else {
            availableIds[rand] = availableIds[remaining - 1];
        }

        return value;
    }

    function toggleSale() external onlyOwner {
        paused = paused == 0 ? 1 : 0;
        emit TogglePaused(paused == 1);
    }

    function setPayeeAddress(address _owner) external onlyOwner {
        payeeWallet = _owner;
    }

    function setPayoutToken(address _tokenAddress) external onlyOwner {
        payoutToken = _tokenAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setSignAddress(address _signAddress) external onlyOwner {
        signAddress = _signAddress;
    }
}