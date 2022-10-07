// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error KDriveNFT_IdNotExisted(uint256 id);
error KDriveNFT_NotEnoughSupply(uint256 id, uint256 remain);
error KDriveNFT_NotEnoughPaymentAmount(
    uint256 id,
    uint256 requiredAmount,
    uint256 sentAmount
);
error KDriveNFT_NoProceeds();
error KDriveNFT_NotEnoughAllowedTokenAmount(
    uint256 requiredAmount,
    uint256 allowedAmount
);

contract KDriveNFT is ERC1155Upgradeable, OwnableUpgradeable {
    uint256 public constant OLD = 0;
    uint256 public constant COMMON = 1;
    uint256 public constant FUTURE = 2;
    uint256 public constant VISION = 3;

    string public constant name = "KDrive";

    IERC20 public s_currencyToken;
    uint256[] public s_supplies;
    uint256[] public s_mintRate;
    uint256[] public s_mintedCount;

    event Minted(address indexed account, uint256 indexed id, uint256 amount);

    modifier idExisted(uint256 id) {
        uint256[4] memory ids = [OLD, COMMON, FUTURE, VISION];

        bool isExisted = false;

        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == id) {
                isExisted = true;
                break;
            }
        }

        if (!isExisted) {
            revert KDriveNFT_IdNotExisted(id);
        }

        _;
    }

    modifier enoughSupply(uint256 id, uint256 amount) {
        if (s_supplies[id] != 0) {
            if (s_mintedCount[id] + amount > s_supplies[id]) {
                revert KDriveNFT_NotEnoughSupply(
                    id,
                    s_supplies[id] - s_mintedCount[id]
                );
            }
        }

        _;
    }

    modifier enoughPaymentAmount(
        uint256 id,
        uint256 amount,
        uint256 paymentSent
    ) {
        if (paymentSent < s_mintRate[id] * amount) {
            revert KDriveNFT_NotEnoughPaymentAmount(
                id,
                s_mintRate[id] * amount,
                paymentSent
            );
        }
        _;
    }

    modifier hasProceeds() {
        if (address(this).balance <= 0) {
            revert KDriveNFT_NoProceeds();
        }
        _;
    }

    modifier enoughAllowedTokenAmount(
        uint256 id,
        address account,
        uint256 amount
    ) {
        uint256 allowedAmount = s_currencyToken.allowance(
            account,
            address(this)
        );
        if (allowedAmount < s_mintRate[id] * amount) {
            revert KDriveNFT_NotEnoughAllowedTokenAmount(
                s_mintRate[id] * amount,
                allowedAmount
            );
        }
        _;
    }

    function initialize(
        address _currencyToken,
        uint256[] memory _supplies,
        uint256[] memory _mintRate,
        uint256[] memory _mintedCount
    ) public initializer {
        __Ownable_init();
        __ERC1155_init(
            "ipfs://bafybeiec7d5bsw5sbng72g3zrxilw3rupwooersqfqrvh5y4gdk7xeq4qq/{id}.json"
        );

        s_currencyToken = IERC20(_currencyToken);
        s_supplies = _supplies;
        s_mintRate = _mintRate;
        s_mintedCount = _mintedCount;
    }

    function getSupply(uint256 id) public view returns (uint256) {
        return s_supplies[id];
    }

    function getMintRate(uint256 id) public view returns (uint256) {
        return s_mintRate[id];
    }

    function getMintedCount(uint256 id) public view returns (uint256) {
        return s_mintedCount[id];
    }

    function getPaymentAmount(uint256 id, uint256 amount)
        public
        view
        returns (uint256)
    {
        return s_mintRate[id] * amount;
    }

    function getIds()
        public
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (OLD, COMMON, FUTURE, VISION);
    }

    function uri(uint256 id) public pure override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "ipfs://bafybeiec7d5bsw5sbng72g3zrxilw3rupwooersqfqrvh5y4gdk7xeq4qq/",
                    Strings.toString(id),
                    ".json"
                )
            );
    }

    function mint(
        uint256 id,
        uint256 amount,
        uint256 paymentAmount
    )
        public
        payable
        idExisted(id)
        enoughSupply(id, amount)
        enoughAllowedTokenAmount(id, msg.sender, amount)
    {
        s_currencyToken.transferFrom(msg.sender, address(this), paymentAmount);

        _mint(msg.sender, id, amount, "");

        emit Minted(msg.sender, id, amount);
    }

    function withdraw() public payable onlyOwner hasProceeds {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function updateMintRate(uint256 id, uint256 newRate) public onlyOwner {
        s_mintRate[id] = newRate;
    }

    function updateSupply(uint256 id, uint256 newSupply) public onlyOwner {
        s_supplies[id] = newSupply;
    }

    function updateCurrencyToken(address newCurrencyTokenAddress)
        public
        onlyOwner
    {
        s_currencyToken = IERC20(newCurrencyTokenAddress);
    }

    function setUri(string memory newUri) public onlyOwner {
        _setURI(newUri);
    }
}