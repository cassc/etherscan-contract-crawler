// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/*
                          ,╓m══m═══╦╖
                      ≡*╙               ▒w     ,╓∞═ªª▒░⌠⌠░░▒ª*─«┐,
                  ,M                      RÉ╙                      ╙k
                  ┌╩                        ╙▄                        ▓
                  D                           ▀
                ▌            ─────^^^──~.     ▀    . ~──────── ^ M╨╜"╙▒▒░ªw
                M      `                      `╙`                           ▒,
            ╓m▓                                 ─                            &
            ╔`  ▌         ╜╩╝"`                `"╙╝▒`          . ~─^^``         "N
          ┌▀   ╙        ▒╦            ,╔gN&&Ng╖      ▌   .─`    ╚╩╜"""`        `"▐
        g                 R,       Æ▓▓  ╙▓▓▓▓▓▓     ╟`"""""`      4▓████▓▓N,     K
        ╔                    ░╦╖   ▐▓▓▓▓██▓▓▓▀╙▓█   ,`           ┌█▓▌,▓▓▓▓▓▓▓     Å
      Ω                        └╔╦▀███g█▓▓▓█▓▓▓,╓╦w            █▓▓▌▀▓▓▓█` ▓▓  ╓▐
      ▓                                         ╓*`  ▒╔╦╖,,     ▓▓▓█▓▓▓▓██▓▀▀▒▄w╩
    ╒                         `"`^^^^^^^^""`    ─               └▒     ,,.═]Ö
    ▌                                  ,,,╓─^`         ,,▄▄▄▄▄wwwæ▄▄,,,,,╓@▀M
    Ü                           ,╓╥wwµ,▐ ```````````````````` `╒▌         ▓
    █                          ╒▀       j                      µ --------<
    U                         ╘µ       ─4   Never              µ,,, -- -"
    █▌                          "Rw,,,  j                      ▌ 
    ██                                  j       Gib            |   
      █▓,                                ▐                      ╙ 
      █╩▀█ªw╓,                       ╓æM╩          Up           U  
    ▓▀    ▀▄   `╙╙ⁿⁿMMM∞mw∞∞∞ww▄▄▄æM╜     ╩▀▀╦╦╖                Ü 
  ▓`        ╙Nm╗,     ,╓gm0É╜╙ ▐U           µ╨                  U   
  ▌            ,▄8▀▀╙          ▐         ▀▀╦,       Fren        U   
  Ü     ,,▄K╨╜`                └▄    ,µg▄╙'                     U   
    `╙`╙                   ╓▄æKM▀╝╙`    ▐                      ▐▓  
                  ,,▄mM╜╙`              ▐    ,,,,,          ,,,╟     
  ╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╝╝╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╜╝╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩╩
*/

/// @title Permittable ERC-20 - "NeverGibUpFren"
/// @notice ERC-20 with a fixed supply of 100,000 tokens, transfer limit of 1,000, and a 5 minute transfer cooldown  
contract NeverGibUpFren is ERC20, ERC20Permit {
  address private deployooor;

  uint256 private deployed;

  mapping(address => uint256) private transferTimestamps;

  /// @notice Creates the token, sets the deployer (crowdsale), 
  constructor() ERC20("NeverGibUpFren", "NGUF") ERC20Permit("NeverGibUpFren") {
    deployooor = msg.sender;

    // a k for the deployooor
    _mint(deployooor, 1000 * 10 ** decimals());
    
    // a k for vitalik
    _mint(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045, 1000 * 10 ** decimals());

    // supply
    uint256 supply = (100000 - 2000) * 10 ** decimals();
    _mint(deployooor, supply);
  }

  /// @notice Crowdsale finished deployment
  function finishDeployment() external {
    assert(msg.sender == deployooor);
    assert(deployed == 0);
    deployed = block.timestamp;
  }

  /// @notice Ensures anti-bot, anti-sniping, anti-whale, and transfer cooldown measures
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    if (deployed == 0 || from == deployooor) {
      // as long as token and pair deployment isn't finished
      super._beforeTokenTransfer(from, to, amount);
      return;
    }
    
    // no sniping, lock for half an hour after deployment
    require(block.timestamp >= (deployed + 30 minutes), "initial lock");

    // no whales, prevent transfers larger than 1% of total supply in one transaction
    require(
      amount <= 1000000000000000000000,
      "no whale transfer allowed (max. 1000 tokeens)"
    );
    
    // no bots, transfer cooldown
    require(
      (block.timestamp - transferTimestamps[msg.sender]) >= 5 minutes,
      "you can only make 1 transfer every 5 minutes"
    );

    // safe transfer timestamp
    transferTimestamps[msg.sender] = block.timestamp;

    super._beforeTokenTransfer(from, to, amount);
  }
}