// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

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

/// @title ERC-20 - "NeverGibUpFren"
/// @notice ERC-20 with a fixed supply of 100,000 tokens, transfer limit of 1,000, and a 5 minute transfer cooldown  
contract NeverGibUpFren is ERC20, Ownable {
  uint256 private deployed = 0;

  mapping(address => uint256) private transferTimestamps;

  /// @notice Creates the token 
  constructor() ERC20("NeverGibUpFren", "NGUF") {
    // create supply
    uint256 supply = 100000 * 10 ** decimals();
    _mint(owner(), supply);
  }

  /// @notice finished deployment
  function finishDeployment() onlyOwner external {
    assert(deployed == 0);
    deployed = block.timestamp;
    renounceOwnership();
  }

  /// @notice Ensures anti-bot, anti-sniping, anti-whale, and transfer cooldown measures
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    if (deployed == 0) {
      // as long as token and pair deployment isn't finished
      if (from == owner() || to == owner()) {
        super._beforeTokenTransfer(from, to, amount);
        return;
      } else {
        revert();
      }
    }

    // no whales, prevent transfers larger than 1% of total supply in one transaction
    require(
      amount <= 1000100000000000000000,
      "no whale transfer allowed (max. 1000 tokeens)"
    );
    
    // no bots, transfer cooldown
    require(
      (block.timestamp - transferTimestamps[tx.origin]) >= 5 minutes,
      "you can only make 1 transfer every 5 minutes"
    );

    // safe transfer timestamp
    transferTimestamps[tx.origin] = block.timestamp;

    super._beforeTokenTransfer(from, to, amount);
  }
}