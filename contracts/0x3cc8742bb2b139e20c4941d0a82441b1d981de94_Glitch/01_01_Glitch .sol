/*
Introducing Glitch, a groundbreaking cryptocurrency designed to liberate individuals from the constraints of the matrix. Glitch is more than just a digital currency; it represents a revolutionary approach to decentralization and personal freedom. Built upon cutting-edge blockchain technology, Glitch offers an alternative financial system that empowers users to break free from the control of centralized authorities. Whether you seek to challenge the status quo or embark on a journey of self-discovery, Glitch opens the door to a future where you can shape your own destiny.

Are you ready to escape the matrix?

Website: www.glitcherc.com
Telegram: https://t.me/EscapeTheMatrixETH
Twitter: https://twitter.com/Glitchcoinerc20
*/

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function matrix(address recipient, uint256 amount) external returns (bool);
    function soon(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function glitch(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Glitch is IERC20{
    

    function name() public pure returns (string memory) {
        return "Glitch";
    }

    function symbol() public pure returns (string memory) {
        return "GLITCH";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 100000000;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function matrix(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function soon(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function glitch(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    receive() external payable {}
    
}