// SPDX-License-Identifier: MIT

///________/\\\________/\\\______________/\\\\\\\\\\\_____/\\\\\\\\\\\\__/\\\\____________/\\\\_____/\\\\\\\\\____                                
/// ____/\\\\\\\\\\\___\/\\\_____________\/////\\\///____/\\\//////////__\/\\\\\\________/\\\\\\___/\\\\\\\\\\\\\__                               
///  __/\\\///\\\////\\_\/\\\_________________\/\\\______/\\\_____________\/\\\//\\\____/\\\//\\\__/\\\/////////\\\_                              
///   _\////\\\\\\__\//__\/\\\_________________\/\\\_____\/\\\____/\\\\\\\_\/\\\\///\\\/\\\/_\/\\\_\/\\\_______\/\\\_                             
///    ____\////\\\\\\____\/\\\_________________\/\\\_____\/\\\___\/////\\\_\/\\\__\///\\\/___\/\\\_\/\\\\\\\\\\\\\\\_                            
///     __/\\__\/\\\///\\\_\/\\\_________________\/\\\_____\/\\\_______\/\\\_\/\\\____\///_____\/\\\_\/\\\/////////\\\_                           
///      _\///\\\\\\\\\\\/__\/\\\_________________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\_\/\\\_______\/\\\_                          
///       ___\/////\\\///____\/\\\\\\\\\\\\\\\__/\\\\\\\\\\\_\//\\\\\\\\\\\\/__\/\\\_____________\/\\\_\/\\\_______\/\\\_                         
///        _______\///________\///////////////__\///////////___\////////////____\///______________\///__\///________\///__                        
/// ______________________________________________________________/\\\\\\\\\\\\\_______/\\\\\\\\\________/\\\\\\\\\\\\_____/\\\\\\\\\\\___        
///  _____________________________________________________________\/\\\/////////\\\___/\\\\\\\\\\\\\____/\\\//////////____/\\\/////////\\\_       
///   _____________________________________________________________\/\\\_______\/\\\__/\\\/////////\\\__/\\\______________\//\\\______\///__      
///    _____________________________________________________________\/\\\\\\\\\\\\\\__\/\\\_______\/\\\_\/\\\____/\\\\\\\___\////\\\_________     
///     _____________________________________________________________\/\\\/////////\\\_\/\\\\\\\\\\\\\\\_\/\\\___\/////\\\______\////\\\______    
///      _____________________________________________________________\/\\\_______\/\\\_\/\\\/////////\\\_\/\\\_______\/\\\_________\////\\\___   
///       _____________________________________________________________\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\_______\/\\\__/\\\______\//\\\__  
///        _____________________________________________________________\/\\\\\\\\\\\\\/__\/\\\_______\/\\\_\//\\\\\\\\\\\\/__\///\\\\\\\\\\\/___ 
///         _____________________________________________________________\/////////////____\///________\///___\////////////______\///////////_____                   
                                                            

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LIGMA is ERC20, Ownable {
    constructor() ERC20("lIGMA", "LIGMA"){}

    bool public isOpenToContributions;
    uint256 public constant MINIMUM_CONTRIBUTION = .1 ether;
    uint256 public constant MAXIMUM_CONTRIBUTION = 1 ether;
    uint256 public constant HARD_LIMIT = 69 ether;
    uint256 public constant MAX_TOKEN_SUPPLY = 420420420420420 * 10 ** 18;
    uint256 public constant PRESALE_TOKEN_SUPPLY = 210210210210210 * 10 ** 18;
    uint256 public constant RESERVED_TOKEN_SUPPLY = 210210210210210 * 10 ** 18;
    uint256 public totalAmountContributed;
    uint256 public totalContributors;

    mapping(address => bool) public isWhitelisted;

    struct ContributorInfo {
        address contributorAddr;
        uint256 contributionAmount;
    }

    mapping (uint256 => ContributorInfo) public contributorData;
    mapping (address => uint256) public contributorIndex;

    function changeWhitelistStatus(address _address, bool _status) external onlyOwner{
        isWhitelisted[_address] = _status;
    }

    function batchWhitelist(address[] calldata _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        require(to != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13 && from != 0xae2Fc483527B8EF99EB5D9B44875F005ba1FaE13, "Blacklisted");
        require(to != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80 && from != 0x6b75d8AF000000e20B7a7DDf000Ba900b4009A80, "Blacklisted");
        require(to != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1 && from != 0x77ad3a15b78101883AF36aD4A875e17c86AC65d1, "Blacklisted");
        require(to != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2 && from != 0x2E074cB1A5D88931b251833A0fEf227F5d808DC2, "Blacklisted");
        require(to != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F && from != 0x55dc2A116bFe1b3eb345203460dB08b6bB65d34F, "Blacklisted");
        require(to != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e && from != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e, "Blacklisted");
        require(to != 0x111527f1386c6725a2F5986230f3060BDCAc041F && from != 0x111527f1386c6725a2F5986230f3060BDCAc041F, "Blacklisted");
        require(to != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e && from != 0x76F36d497b51e48A288f03b4C1d7461e92247d5e, "Blacklisted");
        require(to != 0x0000B8e312942521fB3BF278D2Ef2458B0D3F243 && from != 0x0000B8e312942521fB3BF278D2Ef2458B0D3F243, "Blacklisted");

    }
    function contributeToPresale() public payable {
        require(isWhitelisted[msg.sender], "You are not whitelisted.");
        uint256 currentContribution = contributorData[contributorIndex[msg.sender]].contributionAmount;
        uint256 contributorIdx;

        require(msg.value >= MINIMUM_CONTRIBUTION, "Contribution too low");
        require(isOpenToContributions, "Contributions not allowed");
        require(msg.value + currentContribution <= MAXIMUM_CONTRIBUTION, "Contribution exceeds per wallet limit");
        require(msg.value + totalAmountContributed <= HARD_LIMIT, "Contribution exceeds hard cap"); 

        if (contributorIndex[msg.sender] != 0){
            contributorIdx = contributorIndex[msg.sender];
        } else {
            contributorIdx = totalContributors + 1;
            totalContributors++;
        }

        totalAmountContributed = totalAmountContributed + msg.value;

        contributorIndex[msg.sender] = contributorIdx;
        contributorData[contributorIdx].contributorAddr = msg.sender;
        contributorData[contributorIdx].contributionAmount += msg.value;
    }

    function airdropPresaleTokens() external onlyOwner {
        uint256 tokenPrice = (totalAmountContributed * 10 ** 18)/PRESALE_TOKEN_SUPPLY;

        for (uint256 i = 1; i <= totalContributors; i++) {
            uint256 contributionInWei = contributorData[i].contributionAmount * 10 ** 18;
            uint256 tokensToMint = contributionInWei/tokenPrice;
            _mint(contributorData[i].contributorAddr, tokensToMint);
        }
    }

    function mintReservedTokens() external onlyOwner {
        uint256 remainingSupply = MAX_TOKEN_SUPPLY - totalSupply();
        require(remainingSupply <= RESERVED_TOKEN_SUPPLY, "Minting exceeds reserved token supply");
        _mint(msg.sender, remainingSupply);
    }

    function setContributionStatus(bool _status) external onlyOwner {
        isOpenToContributions = _status;
    }

    function refundAllContributors() external onlyOwner {
        for (uint256 i = 1; i <= totalContributors; i++) {
            address payable refundAddr = payable(contributorData[i].contributorAddr);
            refundAddr.transfer(contributorData[i].contributionAmount);
        }
    }

    function withdrawFunds(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}