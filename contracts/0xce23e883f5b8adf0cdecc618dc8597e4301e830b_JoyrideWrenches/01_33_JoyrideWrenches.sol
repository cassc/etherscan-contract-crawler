//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./JoyrideParts.sol";

contract JoyrideWrenches is ERC1155Supply, Ownable {
    bool public saleIsActive = false;
    bool public airdropAvailable = true;
    uint256 constant public TOKEN_ID = 1;
    uint256 constant MAX_TOKENS = 3000;
    uint256 tokenPrice = 0.09 ether;

    JoyrideParts private joyrideParts;
    address private joyrideAddress;

    mapping (uint256 => bool) private _claimedTokens;

    constructor(string memory _baseURI, address _joyridePartsAddress) ERC1155(_baseURI) {
        joyrideParts = JoyrideParts(_joyridePartsAddress);
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function disableAirdrop() public onlyOwner {
        airdropAvailable = false;
    }

    /// @dev Buy wrenches
    function buy(uint256 amount) public payable {
        require(saleIsActive, "Sale is not active");
        require(msg.value == tokenPrice * amount, "Invalid value");
        require(totalSupply(TOKEN_ID) + amount <= MAX_TOKENS, "All wrenches minted");

        _mint(msg.sender, TOKEN_ID, amount, "");
    }

    /// @dev Airdrop boosts to addresses based on how many car parts they own
    /// does not keep track of which tokens claimed so either use airdrop or claim
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) public onlyOwner {
        require(airdropAvailable, "Airdrop is not available");
        require(addresses.length == amounts.length, "Argument lenghts missmatch");
        for (uint256 idx = 0; idx < addresses.length; idx++) {
            _mint(addresses[idx], TOKEN_ID, amounts[idx], "");
        }
    }

    /// @dev Called from the Joyrides contract during assembly
    function useInAssembly(address from) external {
        require(msg.sender == joyrideAddress, "Not the assembler");

        _burn(from, TOKEN_ID, 1);
    }

    /// @dev Set the address of Joyride contract for preapproval, cannot be changed once it's set
    function setJoyrideAddress(address _joyrideAddress) public onlyOwner {
        joyrideAddress = _joyrideAddress;
    }

    /// @dev Set the price of a Wrench
    function setWrenchPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    /// @notice Allows the owner to withdraw funds stored in the contract.
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        uint256 devCut = balance * 133 / 1000;
        payable(0x6603418703e027019d6E8060542E6193509077B0).transfer(devCut);
        payable(0xC09252422a1BDeB0bde16d12C9a5880BC7Fb3F53).transfer(devCut);
        payable(0xf21f1195456c90Ce20410cADd5c0C51F8af3fBFA).transfer(devCut);

        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Allows the owner to update the metadata.
    function setURI(string calldata uri_) external onlyOwner {
        _setURI(uri_);
    }
}