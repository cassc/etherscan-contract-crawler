// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FrenchConcertSchedule is Ownable {

    address payable public tipRecipient;

    uint256 public minTip;

    uint256 public minBalance;

    SignUpUser[] private june18Registered;
    SignUpUser[] private june24Registered;
    SignUpUser[] private june25Registered;
    SignUpUser[] private july19Registered;
    SignUpUser[] private aug6Registered;
    SignUpUser[] private aug11Registered;
    SignUpUser[] private aug16Registered;
    SignUpUser[] private aug19Registered;
    SignUpUser[] private aug20Registered;
    SignUpUser[] private oct141516Registered;

    struct SignUpUser {
        address account;
        string name;
        string email;
        string twitter;
        uint256 tip;
    }

    struct ConcertInfo {
        string date;
        string city;
        string performance;
    }

    function setTip(address payable recipient, uint256 tip) external onlyOwner {
        tipRecipient = recipient;
        minTip = tip;
    }

    function setMinBalance(uint256 amount) external onlyOwner {
        minBalance = amount;
    }

    function June18Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Saturday, June 18", "ESTERO, FL", "All Gas No Brakes Concert Event @ Hertz Arena");
    }

    function June18Registered() public view returns (SignUpUser[] memory){
        return june18Registered;
    }

    function June24Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Friday, June 24", "Las Vegas, NV", " Drais Nightclub");
    }

    function June24Registered() public view returns (SignUpUser[] memory){
        return june24Registered;
    }

    function June25Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Saturday, June 25", "Las Vegas, NV", "Drais Pool");
    }

    function June25Registered() public view returns (SignUpUser[] memory){
        return june25Registered;
    }

    function July19Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Tuesday, July 19", "Valetta, Malta", "Isle of Malta MTV @ Il Fosses Square");
    }

    function July19Registered() public view returns (SignUpUser[] memory){
        return july19Registered;
    }

    function Aug6Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Saturday, Aug 6", "Montreal, QC", "Ilesoniq Festival");
    }

    function Aug6Registered() public view returns (SignUpUser[] memory){
        return aug6Registered;
    }

    function Aug11Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Thursday, Aug 11", "Ibiza, ES", "Amnesia Ibiza");
    }

    function Aug11Registered() public view returns (SignUpUser[] memory){
        return aug11Registered;
    }

    function Aug16Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Tuesday, Aug 16", "Gialos, Greece", "Santanna Beach Club");
    }

    function Aug16Registered() public view returns (SignUpUser[] memory){
        return aug16Registered;
    }

    function Aug19Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Friday, Aug 19", "Las Vegas, NVe", "Drais Nightclub");
    }

    function Aug19Registered() public view returns (SignUpUser[] memory){
        return aug19Registered;
    }

    function Aug20Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Saturday, Aug 20", " Las Vegas, NV", "Drais Beachclub");
    }

    function Aug20Registered() public view returns (SignUpUser[] memory){
        return aug20Registered;
    }

    function Oct141516Concert() public pure returns (ConcertInfo memory){
        return ConcertInfo("Oct 14, 15, & 16", "Bangalore / Delhi / Kolkata India", "UB City / Golflink / Westside Pavilion");
    }

    function Oct141516Registered() public view returns (SignUpUser[] memory){
        return oct141516Registered;
    }

    function _signUpCheck() internal {
        require(msg.value >= minTip, "tip too low");
        require(msg.sender.balance >= minBalance, "insufficient balance");

        if (msg.value > 0) {
            Address.sendValue(tipRecipient, msg.value);
        }
    }

    function signUpJune18(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        june18Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpJune24(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        june24Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpJune25(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        june25Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpJuly19(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        july19Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpAug6(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        aug6Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpAug11(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        aug11Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpAug16(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        aug16Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpAug19(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        aug19Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpAug20(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        aug20Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }

    function signUpOct141516(string calldata name, string calldata email, string calldata twitter) external payable {
        _signUpCheck();
        oct141516Registered.push(SignUpUser(msg.sender, name, email, twitter, msg.value));
    }
}