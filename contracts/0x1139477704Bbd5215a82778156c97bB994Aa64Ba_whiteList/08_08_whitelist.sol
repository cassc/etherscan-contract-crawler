// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/AccessControl.sol';

contract whiteList is AccessControl {
    bytes32 SALE_ROLE = keccak256('SALE_ROLE');
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(SALE_ROLE, DEFAULT_ADMIN_ROLE);
        whiteListValue[0x7f0BEcEE148705db6CdA8d6A9AdE598771EbC289] = 5;
        whiteListValue[0x0ECBA421A8637F514D593f5387104fFDd776Ec7A] = 5;
        whiteListValue[0x18C0D4338CB5261d7758c3572ACBf59A70e8783b] = 5;
        whiteListValue[0x27cf7b699114Db0eb5f2123c85DF4141C54A15dF] = 5;
        whiteListValue[0xbe4a67a7dA7CB2640B1Aa8Ba6c5056095b3Cda98] = 5;
        whiteListValue[0x4fEB252AB1fc8a5Bd56C264E3188A17A5Fe5BbE1] = 5;
        whiteListValue[0x1df208fE495E3CE944Fad918B07B233D0bE44A93] = 5;
        whiteListValue[0x5159b917973A589C1fB3d06B0bDcb7B868994FFE] = 5;
        whiteListValue[0x72FFD6B8d913370596c433A2B8dCE121AcF2fFA0] = 5;
        whiteListValue[0xD165D7E0A51220BC201e008761c561b98e91464F] = 5;
        whiteListValue[0xceF7a422e8091eFc0C2c2dcee4C33800c7B78198] = 5;
        whiteListValue[0x06421511787Cfda17D8fa6adB9B53c688802AE7e] = 5;
        whiteListValue[0xC6cb7e3AaD5a7F1C9A8227920D13a0Bc6a6Ac7d4] = 5;
        whiteListValue[0xc7bAFE572bA6113d3e109BFE9E561100f0c72b44] = 5;
        whiteListValue[0xC7c5E59B60573cE6c3f6f810266Eda567477E1e4] = 5;
        whiteListValue[0x4f02B8e29d8B4De90152d5d709be74e80f16bEd5] = 5;
        whiteListValue[0x77d3FDfc3F73D90F066400102E5a32d0e206B2c7] = 5;
        whiteListValue[0xa3E35e43353De29DD3460CB9BE19AF1Cc9c1C4d0] = 5;
        whiteListValue[0x369a0068C79840B9Ca67BC8308826de6D7e7ac85] = 5;
        whiteListValue[0x3f6338c5DF7a407b981A34539AE9ba785af6BCA7] = 5;
        whiteListValue[0x839F099D7EA3C0a323E4633237B18694Af245C5A] = 5;
        whiteListValue[0xBb018884462019b3A97B798E1D298a5215e13e26] = 5;
        whiteListValue[0x5795072E11bC8f5900Ebfb6CC93E555bA7e4542b] = 5;
        whiteListValue[0xAEe475B911cEC5Dfb03b2389b3A08a5707242197] = 5;
        whiteListValue[0x9fe35D27D7c14B902d5547dC59bD6A8029FCB5BF] = 5;
        whiteListValue[0x6012820189edc1855F9a8BE659882D64E75b4b82] = 5;
        whiteListValue[0xF392CD7AF7Ec6de4fD6d2f1EB4133931a097743B] = 5;
        whiteListValue[0xf76665C8bf60B6F15C2B89bb58302dE381A5C728] = 5;
        whiteListValue[0x75742D86B419aEF6A259Cf4dF8047CB29F1fC317] = 5;
        whiteListValue[0x5e5e3530B49d1d6C94a444badBb2E252234cF26f] = 5;
        whiteListValue[0x7BE2978f8f32ba6F448B5d371dC73c29d2F6eAd2] = 5;
        whiteListValue[0x1613980200fe719E92Ae6A451Bfdc2cc576069E8] = 5;
        whiteListValue[0x678a2fc326dEE5d986C48Ee75992F784Ab3a561c] = 5;
        whiteListValue[0x9f1A7D9917CD54362191eb33a4DA0cc14acECFBf] = 5;
        whiteListValue[0x58AB66ac351fDF82D86bF375E152f3D12eEC786D] = 5;
        whiteListValue[0x3217F371e54851e26a30869DF32579f98AC174a5] = 5;
        whiteListValue[0xF0c4523Aa85DEd516276bdbE5AE021df5BBb4b04] = 5;
        whiteListValue[0xED7713E148581d3117c745e938E7C57ece65EEc5] = 5;
        whiteListValue[0x68b332BB6543221d2c0F05020E4B7EB17d9eCd8E] = 5;
        whiteListValue[0xB022347858eF2369F2ba4997f5c420E5ACCFc668] = 5;
        whiteListValue[0xB7f711C015373B47daDFCa36180b1cf576cdAE9b] = 5;
        whiteListValue[0x32e84c29895d169E4baF1ba4980CAF4824CEC608] = 5;
        whiteListValue[0x32bCF5Aee95c3BB56BD84d7e5ffc91e9FC0e3De1] = 5;
        whiteListValue[0x108345343771888A4554d0B27C0D04073405b8F3] = 5;
        whiteListValue[0x7c9F237a4Bf59F4bf9D2E7137394Cc2eF1231091] = 5;
        totalAmount += 225;
    }

    mapping (address => uint256) whiteListValue;
    mapping (address => uint256) whiteListUsed;
    uint256 totalAmount;
    uint256 totalUsedAmount;

    function addWhiteList(address _walletAddress, uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(whiteListValue[_walletAddress] == 0);
        whiteListValue[_walletAddress] = _value;
        totalAmount += _value;
    }

    function reduceWhiteList(address _walletAddress, uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require((whiteListValue[_walletAddress] - whiteListUsed[_walletAddress]) >= _value);
        whiteListValue[_walletAddress] -= _value;
        totalAmount -= _value;
    }

    function revokeWhitelist(address _walletAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(whiteListValue[_walletAddress] != 0);
        uint256 _revokeamount = whiteListValue[_walletAddress];
        whiteListValue[_walletAddress] = 0;
        totalAmount -= _revokeamount;
    }

    function changeWhitelistAmount(address _walletAddress, uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(whiteListValue[_walletAddress] >= 1);
        require(_value >= 1);
        uint256 _revokeamount = whiteListValue[_walletAddress];
        whiteListValue[_walletAddress] = _value;
        totalAmount -= _revokeamount;
        totalAmount += _value;
    }

    function addWhiteListUsed(address _walletAddress) public onlyRole(SALE_ROLE) {
        require(whiteListValue[_walletAddress] > whiteListUsed[_walletAddress]);
        whiteListUsed[_walletAddress] ++;
        totalUsedAmount ++;
    }

    function checkWhiteListRemainAmount(address _walletAddress) public view returns(uint256) {
        return whiteListValue[_walletAddress] - whiteListUsed[_walletAddress];
    }

    function checkTotalAmount() public view returns(uint256) {
        return totalAmount;
    }

    function checkTotalUsedAmount() public view returns(uint256) {
        return totalUsedAmount;
    }

    function checkTotalRemainAmount() public view returns(uint256) {
        return totalAmount - totalUsedAmount;
    }

    function checkWhiteList(address _address) public view returns(uint256) {
        return whiteListValue[_address];
    }

    function checkWhiteListUsed(address _address) public view returns(uint256) {
        return whiteListUsed[_address];
    }
    
}