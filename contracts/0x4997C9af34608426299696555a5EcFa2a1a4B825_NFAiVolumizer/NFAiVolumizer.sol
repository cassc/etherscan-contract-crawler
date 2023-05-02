/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface AIVolumizer {
    function volumeTokenTransaction(address _contract) external;
    function volumeETHTransaction(address _contract) external;
}

contract NFAiVolumizer is Auth {
    using SafeMath for uint256;
    AIVolumizer volumizer;
    bool volumeAllowed = false;
    bool ETHVolume = false;
    bool tokenVolume = true;
    address tokenContract;

    receive() external payable {}
    constructor() Auth(msg.sender) {
        volumizer = AIVolumizer(0xc4a297FEEabde487Fc2b8E66E2BFa64C3e54747c);
        tokenContract = address(0x8eEcaad83a1Ea77bD88A818d4628fAfc4CaD7969);
        authorize(msg.sender); 
        authorize(address(this));
    }

    function setTokenContract(address _token) external authorized {
        tokenContract = _token;
    }

    function setParameters(bool _volumeAllowed, bool _ETHVolume, bool _tokenVolume) external authorized {
        volumeAllowed = _volumeAllowed; ETHVolume = _ETHVolume; tokenVolume = _tokenVolume;
    }

    function Volumizer() external {
        if(ETHVolume && !tokenVolume){volumeETHTransaction(tokenContract);}
        if(!ETHVolume && tokenVolume){volumeTokenTransaction(tokenContract);}
    }

    function volumeTokenTransaction(address _contract) internal {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeTokenTransaction(_contract);
    }

    function volumeETHTransaction(address _contract) internal {
        require(volumeAllowed || isAuthorized(msg.sender), "Volumizer Dictates Function");
        volumizer.volumeETHTransaction(_contract);
    }
}