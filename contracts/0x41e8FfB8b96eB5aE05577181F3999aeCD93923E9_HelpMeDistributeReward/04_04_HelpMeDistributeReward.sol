// SPDX-License-Identifier: MIT

///@author helpmedebugthis.eth
///@notice Everthing you win or not,
///@notice will have an echo.

/*
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
(((((((((((((((((((((((((((((((((@%/(&@/((#@%@@@#(((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((# $.(&%@&@@ $.&(@@@(((((((((((((((((((((((((((((
(((((((((((((((((((((((((((((((( (@ %(@(@@    /#@@@&@@((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((@#@@#(((/@,(@ @@#@%#@%@@@@((((((((((((((((((((((
((((((((((((((((((((((((((((((@/((//(///////$/[email protected]@###(&@@@%@@((((((((((((((((((((
((((((((((((((((((((((((((((%,$,/,,$$/$$/////////@/(@%%@%@@@@@@(((((((((((((((((
(((((((((((((((((((((((((((((@@@$/(@@@@$(@@%%%$##$,,@((@@@@@&@#@@(((((((((((((((
(((((((((((@@&/(((((((((((((((((@,., ..    .. .   .$(&@@%@@(/,@@@@&(((((((((((((
((((((((((#,. @@.$ &@(((((((((((((@@@#,,...... (/(@@@%@@# %@&#%/,(@@((((((((((((
(((((((((((@$ ##(( /,[email protected]@#@((((&%%%%(((%%(&#(/,@@@@$ [email protected]&@@(/(%@@@&@@@&((((((((((
(((((((((((@.#(#(%./(..,@&((@@@@./ /$$$(&@@##/  ....,@##//(%#&&@@&@&@@((((((((((
(((((((((((& .$.((#/. . @&@@/@@@   $((&@#&(#(@.. ..(/@/(//##@%@@@@%@@&@(((((((((
((((((((((((&...  .,$,/$$%@%&#/@ @@@@@(#&%(/%%#(////($/((&&@@@@#/.(#&@@(((((((((
((((((((((((@.(/.,##(($ ,@(((((@  .(##@@%%%%%@@&%&((&&%%%%@@#,  (%&@&%#&((((((((
((((((((((((@ $(..#$,%(/[email protected]#&(((((&@@@&&#@@@@@@&@@@@@@&%%@@@@@@@@@@&@&@@%((((((((
(((((((((((((@/ ,...%##(((#@(((((((@%&%@(###@@@@@@@@@@@@(#/#///%%@@@@@@(((((((((
((((((((((((((((&  ,[email protected],[email protected]@@@##@@((@&#@($$. .$/($((@%////((&#&%&%@@@(((((((((((
(((((((((((@%[email protected]@@./(,[email protected]&%@##@%@%@%,@@@%@@@$$((/#@%@@%///(/%#%#&@@@@@/(((((((((((
(((((((((#../,[email protected]@(,.//$&##@      &&@@#@@ @@@@@@%##@/&@((&#%%#&&@@@@@@@@@@((((((
(((((((((((/@@&$,(.$/..,#@@. .$$/,@ ,[email protected]@%@@@( #@@@@&@/@(@@@%%@@&&&%(((((((((((((
(((((((((((((((((((/@@./@@@    $//@/@&$##@@@@@@@%@((((((((((((((((((((((((((((((
((((((((((((((((((((((((((# . ,//$&(((((((((((((%(/(((((((((((((((((((((((((((((
((((((((((((((#@@&,/&((((((&   $#(/((((((((((@(&(%@@(@&%@(((((((((((((((((((((((
((((((((((((((((((%((#(((((%@&%&@@@@&&@(((((((&@@@@@@@@%((&(((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
*/

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HelpMeDistributeReward is Ownable, ReentrancyGuard {
    mapping(address => bool) private whitelist;

    event ReceivedEth(uint256 amount);
    event HMPERewardDistributed(uint256 value, address winner, uint256 icycle);
    event RoyaltyRewardDistributed(uint256 value, address winner, uint256 idate);

    constructor() {
        whitelist[msg.sender] = true;
    }

    modifier isWhiteListed() {
        require(whitelist[msg.sender] == true, 'sender is not whitelisted');
        _;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }
    
    function revokeWhitelist(address _address) public onlyOwner {
        whitelist[_address] = false;
    }


    function distributeRoyaltyReward(address payable[] calldata _addresses, uint256[] calldata _values, uint256 _idate) 
        external
        isWhiteListed
        payable {
        for (uint256 i =0; i < _addresses.length; i++) {
            (bool sent, ) = _addresses[i].call{value: _values[i]}("");
            require(sent, "Failed to distribute reward. Need !debog");
            emit RoyaltyRewardDistributed(_values[i], _addresses[i], _idate);
        }
    }

    function distributeHmpeReward(address payable[] calldata _addresses, uint256[] calldata _values, uint256 _icycle) 
        external
        isWhiteListed
        payable {
        for (uint256 i =0; i < _addresses.length; i++) {
            (bool sent, ) = _addresses[i].call{value: _values[i]}("");
            require(sent, "Failed to distribute reward. Need !debog");
            emit HMPERewardDistributed(_values[i], _addresses[i], _icycle);

        }
    }

    function debogging() public payable {
        emit ReceivedEth(msg.value);
    }
    receive() external payable  { 
        debogging();
    }

    fallback() external payable {
        debogging();
    }

}