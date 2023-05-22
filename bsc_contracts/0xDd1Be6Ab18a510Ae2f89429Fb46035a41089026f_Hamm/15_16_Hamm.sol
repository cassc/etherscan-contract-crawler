// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./HammRenderer.sol";

struct PiggyBank {
    string name;
    string description;
    address tokenContractAddress;
    uint balance;
}

contract Hamm is ERC721, HammRenderer {
    uint private constant FIRST_PIGGY_BANK_ID = 1;
    uint private nextPiggyBankId = FIRST_PIGGY_BANK_ID;
    mapping(uint => PiggyBank) private piggyBanksById;

    // 0.5%
    uint constant FEE_BPS = 50;

    function calculateFee(uint256 amount) public pure returns (uint256) {
        uint feeAmountBps = amount * FEE_BPS;
        if (feeAmountBps < 10_000) return 0;
        return feeAmountBps / 10_000;
    }

    address private feeReceiverAddress;

    constructor(address _feeReceiverAddress) ERC721("PiggyBank", "PBK") {
        feeReceiverAddress = _feeReceiverAddress;
    }

    event PiggyBankCreated(uint piggyBankId);

    event PiggyBankWithdrawed(uint piggyBankId);

    modifier onlyOwner(uint piggyBankId) {
        require(
            msg.sender == ownerOf(piggyBankId),
            "Only owner can call this function."
        );
        _;
    }

    function createNewPiggyBankForSender(
        string memory name,
        string memory description,
        address tokenContractAddress
    ) external {
        createNewPiggyBank(msg.sender, name, description, tokenContractAddress);
    }

    function createNewPiggyBank(
        address beneficiaryAddress,
        string memory name,
        string memory description,
        address tokenContractAddress
    ) public {
        uint piggyBankId = nextPiggyBankId++;
        PiggyBank storage piggyBank = piggyBanksById[piggyBankId];
        piggyBank.name = name;
        piggyBank.description = description;
        piggyBank.tokenContractAddress = tokenContractAddress;
        piggyBank.balance = 0;
        _safeMint(beneficiaryAddress, piggyBankId);
        emit PiggyBankCreated(piggyBankId);
    }

    function getPiggyBanksIds() external view returns (uint[] memory) {
        return getPiggyBankIdsForAddress(msg.sender);
    }

    function getPiggyBankIdsForAddress(
        address beneficiaryAddress
    ) public view returns (uint[] memory) {
        uint numberOfPiggyBanks = balanceOf(beneficiaryAddress);
        uint[] memory ownedPiggyBankIds = new uint[](numberOfPiggyBanks);
        uint foundPiggyBank = 0;
        for (
            uint piggyBankId = FIRST_PIGGY_BANK_ID;
            piggyBankId < nextPiggyBankId;
            piggyBankId++
        ) {
            if (foundPiggyBank >= numberOfPiggyBanks) break;
            if (!_exists(piggyBankId)) continue;
            if (ownerOf(piggyBankId) == beneficiaryAddress)
                ownedPiggyBankIds[foundPiggyBank++] = piggyBankId;
        }
        return ownedPiggyBankIds;
    }

    function getPiggyBankById(
        uint piggyBankId
    )
        public
        view
        returns (
            string memory name,
            string memory description,
            address tokenContractAddress,
            uint balance,
            address beneficiaryAddress
        )
    {
        name = piggyBanksById[piggyBankId].name;
        description = piggyBanksById[piggyBankId].description;
        tokenContractAddress = piggyBanksById[piggyBankId].tokenContractAddress;
        balance = piggyBanksById[piggyBankId].balance;
        beneficiaryAddress = ownerOf(piggyBankId);
    }

    function depositPiggyBank(
        uint piggyBankId,
        uint amount
    ) public returns (bool) {
        require(
            _exists(piggyBankId),
            "You are depositing on a deleted or not created piggy bank"
        );
        IERC20 inputToken = IERC20(
            piggyBanksById[piggyBankId].tokenContractAddress
        );
        piggyBanksById[piggyBankId].balance += amount;
        return inputToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdrawalPiggyBank(
        uint piggyBankId
    ) public onlyOwner(piggyBankId) returns (bool transfer) {
        uint amount = piggyBanksById[piggyBankId].balance;
        uint fee = calculateFee(amount);
        uint amountToWithdrawer = amount - fee;
        piggyBanksById[piggyBankId].balance = 0;
        IERC20 inputToken = IERC20(
            piggyBanksById[piggyBankId].tokenContractAddress
        );
        transfer = inputToken.transfer(
            ownerOf(piggyBankId),
            amountToWithdrawer
        );
        inputToken.transfer(feeReceiverAddress, fee);
        emit PiggyBankWithdrawed(piggyBankId);
    }

    function deletePiggyBank(uint piggyBankId) public onlyOwner(piggyBankId) {
        withdrawalPiggyBank(piggyBankId);
        _burn(piggyBankId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint piggyBankId = tokenId;
        string memory name = piggyBanksById[piggyBankId].name;
        string memory description = piggyBanksById[piggyBankId].description;
        string memory nftSvg = renderSvg();
        string memory encodedNftSvg = string.concat(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(nftSvg))
        );
        string memory nftMetadata = string.concat(
            "{",
            '"name":',
            string.concat('"', name, '"'),
            ",",
            '"description":',
            string.concat('"', description, '"'),
            ",",
            '"image":',
            string.concat('"', encodedNftSvg, '"'),
            "}"
        );
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(bytes(nftMetadata))
            );
    }
}