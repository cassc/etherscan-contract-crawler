//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

/*
       ^PY??????????????????????????????YP^
      !G!                                !G!
     7BY7???????????????????????????????J?YB7
     5Y                                    Y5
     Y  G:?5YYYYYYYYYYYYYYYYYYYYYYY57:B7   YY
     Y  PJ5                          PJG   YY
     Y  GG7     [email protected]@@@@.   [email protected]@@@@@~   7GG   YY
     Y  GG7    [email protected]#   &[email protected]  #5         ?PG   YY
     Y  GG7    [email protected]@   [email protected]@  ~5??Y5~.   ?PG   YY
     Y  GG7    [email protected]@   [email protected]@        5#   ?PG   YY
     Y  GG7     55JJYP?   PYJJ5P?    7PG   YY
     Y  PPJ                          YPG   YY
     Y  G:YJ77777777777777777777777JY:G7   YY
     Y                            -  +  () Y5
    BJ??????????????????????????????????????JB
   5Y  ?::??::??::??::??::??::??::??::??::?  Y5
 !B.  ^YJ!:JJ7:?J?:7J?^~JJ~^?J7:?J?:7JJ:!JY^  .B!
:G~ :??~:??7.???.7??:~??^^??~:??7.???.7??:~??: ~G:
5P^^~~^~^~~~^~~~^~~~~~~^~^~~~^~~~^^~~^^^~~~^^~~^^P5
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/// @title Stablz Operating System
contract OperatingSystem is ERC20Burnable, Ownable {

    /// @dev whitelist addresses for minting, burning and transferring to or from
    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(whitelist[_msgSender()], "OperatingSystem: Only whitelisted addresses can call this function");
        _;
    }

    event WhitelistUpdated(address account, bool isWhitelisted);

    constructor() ERC20("Operating System", "OS") {
    }

    /// @notice Mint stakedStablz
    /// @param _account Address to mint tokens to
    /// @param _amount Number of tokens to mint
    function mint(address _account, uint _amount) external onlyWhitelisted {
        _mint(_account, _amount);
    }

    /// @notice Burn stakedStablz
    /// @param _amount Amount to burn
    function burn(uint _amount) public override onlyWhitelisted {
        super.burn(_amount);
    }

    /// @notice Burn stakedStablz from an address
    /// @param _account Address to burn from (caller has to be approved)
    /// @param _amount Amount to burn
    function burnFrom(address _account, uint _amount) public override onlyWhitelisted {
        super.burnFrom(_account, _amount);
    }

    /// @notice Update whitelist
    /// @param _account Account
    /// @param _whitelist true = add to whitelist, false = remove from whitelist
    function updateWhitelist(address _account, bool _whitelist) external onlyOwner {
        whitelist[_account] = _whitelist;
        emit WhitelistUpdated(_account, _whitelist);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        if (from != address(0) && to != address(0)) {
            /// @dev tokens can only be transferred to or from whitelisted address
            require(whitelist[from] || whitelist[to], "OperatingSystem: Can only transfer to or from whitelisted addresses");
        }
    }
}