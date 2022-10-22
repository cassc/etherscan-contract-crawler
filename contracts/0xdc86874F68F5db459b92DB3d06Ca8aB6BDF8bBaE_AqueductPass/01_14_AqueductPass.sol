// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

contract AqueductPass is ERC1155, AccessControl, Pausable, ERC1155Burnable {
    mapping(uint256 => MintStep) public IndexToMintStep;
    mapping(address => uint256) public Whitelist;
    mapping(uint256 => uint256) public MintStepToSupply;
    uint256 public currentMintStep;
    uint256 public totalSupply;
    string baseExtension = ".json";
    uint256 public maxPerAddress;
    string public name;
    string public symbol;
    string public tokenUri;

    struct MintStep {
        uint256 price;
        uint256 supply;
        bool onlyWhitelist;
    }

    modifier isEnoughTokensToMint(uint256 amount) {
        require(amount + MintStepToSupply[currentMintStep] <= IndexToMintStep[currentMintStep].supply, "Not enough supply");
        _;
    }

    modifier onlyWhitelist() {
        if (IndexToMintStep[currentMintStep].onlyWhitelist) {
            require(Whitelist[msg.sender] == 1, "You are not in the Whitelist");
        }
        _;
    }

    modifier lessThenMaxPerAddress(uint256 amount_) {
        require(balanceOf(msg.sender, 1) + amount_ <= maxPerAddress, "Max supply per address reached");
        _;
    }

    constructor(uint256 price_, uint256 supply_, bool onlyWhitelist_, string memory uri_, uint256 maxPerAddress_, string memory name_, string memory symbol_) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        IndexToMintStep[0] = MintStep(price_, supply_, onlyWhitelist_);
        currentMintStep = 0;
        setURI(uri_);
        name = name_;
        symbol = symbol_;
        setMaxPerAddress(maxPerAddress_);
    }

    function setURI(string memory newuri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenUri = newuri;
    }

    function uri(uint256 tokenId_)
    public
    view
    override(ERC1155)
    returns (string memory)
    {
        return string(
            abi.encodePacked(tokenUri, "/", "1", baseExtension)
        );

    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function mint(uint256 amount) payable public onlyWhitelist isEnoughTokensToMint(amount) lessThenMaxPerAddress(amount) {
        require(msg.value == amount * IndexToMintStep[currentMintStep].price, "Not enough ETH sent");

        totalSupply += amount;
        MintStepToSupply[currentMintStep] += amount;
        _mint(msg.sender, 1, amount, "Aqueduct pass");
    }

    function nextMintStep(uint256 price_, uint256 supply_, bool onlyWhitelist_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(supply_ > 0, "Supply should be more then 0");

        currentMintStep++;
        IndexToMintStep[currentMintStep] = MintStep(price_, supply_, onlyWhitelist_);
    }

    function addToWhitelist(address[] memory accounts_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < accounts_.length;) {
            Whitelist[accounts_[i]] = 1;

        unchecked {
            i++;
        }
        }
    }

    function deleteFromWhitelist(address[] memory accounts_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < accounts_.length;) {
            delete Whitelist[accounts_[i]];

        unchecked {
            i++;
        }
        }
    }

    function setMaxPerAddress(uint256 maxPerAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerAddress = maxPerAddress_;
    }

    function withdraw(uint256 amount, address payable to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success,) = to.call{value : amount}("");
        require(success);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
    internal
    whenNotPaused
    override(ERC1155)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}