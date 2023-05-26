// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer } from "./royalty/DefaultOperatorFilterer.sol";
import { IMinter } from "./interfaces/IMinter.sol";

//
//                               ..:-=====--:.
//                          .-*#@@@@@@@@@@@@@@@@#+-.
//                       -*%@@@@@@@@@@@@@@@@@@@@@@@@%+:
//                     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
//                   [email protected]@@%##*******#########%%%@@@@@@@@@@%=
//                 [email protected]@@@@@@@@%#***++++========-==*#%%@@@@@@#.
//                *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//              [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@.
//             [email protected]@@@@@@@@@@@@@@@@@@@@. [email protected]@@@@@*:    :[email protected]@@@@@@@@#
//             *@@@@@@@@@@@@@@@@@@@@.   :@@@@=  .+#+: [email protected]@@@@@@@@:
//             %@@@@@@@@@@@@@@@@@@@:  :  [email protected]@@   %@@@@  [email protected]@@@@@@@+
//             @@@@@@@@@@@@@@@@@@@:  [email protected]:  [email protected]@-  [email protected]@@#  [email protected]@@@@@@@%
//            [email protected]@@@@@@@@@@@@@@@@@=  [email protected]@@   [email protected]@-   ..  [email protected]@@@@@@@@#
//             %@@@@@@@@@@@@@@@@#---%@@@#---%@@%+-:-+#@@@@@@@@@@*
//             *@@@@@@@@@@@@@@@@@@@@@@@%#@%#@%%@%%@@@@@@@@@@@@@@-
//             [email protected]@@@@@@@@@@@@@@@@@@@@@@**%-+#*#@#%@@@@@@@@@@@@@%
//              [email protected]@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
//                [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
//                 [email protected]@@@@@@@@%#**++=====-=====-====++#%%@@@#.
//                  .*@@@@%#*******###########%%%%%%@@@@@#=
//                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
//                       :*%@@@@@@@@@@@@@@@@@@@@@@@@%+.
//                          :=*#@@@@@@@@@@@@@@@%#+:
//                                :--===+==--:
//
// RIW & Pellar 2023

contract AOToken is Ownable2Step, ERC721Enumerable, DefaultOperatorFilterer {
  struct Phase {
    bool trading_paused;
    address minter;
    address asset;
  }

  mapping(uint256 => uint256) public token2Phase;
  mapping(uint256 => Phase) public phase2Asset;

  constructor() ERC721("AO ArtBall", "ARTB23") {}

  /* Mint */
  // verified
  function mintBatch(
    uint256 _phase,
    uint256[] calldata _tokenIds,
    address[] calldata _receivers
  ) public {
    require(_tokenIds.length == _receivers.length, "Input mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      mint(_phase, _tokenIds[i], _receivers[i]);
    }
  }

  // verified
  function mint(
    uint256 _phase,
    uint256 _tokenId,
    address _receiver
  ) public {
    require(phase2Asset[_phase].minter == msg.sender, "Invalid phase");
    require(_tokenId >= 6776, "Duplicate token");

    token2Phase[_tokenId] = _phase;
    _mint(_receiver, _tokenId);
  }

  /* View */
  function exists(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for non exists token.");
    return IMinter(phase2Asset[token2Phase[_tokenId]].asset).tokenURI(_tokenId);
  }

  /* Admin */
  // verified
  function setPhase(uint256[] calldata _tokenIds, uint256[] calldata _phases) public onlyOwner {
    require(_tokenIds.length == _phases.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      token2Phase[_tokenIds[i]] = _phases[i];
    }
  }

  // verified
  function setAssetReference(
    uint256[] calldata _phases,
    address[] calldata _minters,
    address[] calldata _assets
  ) public onlyOwner {
    require(_phases.length == _minters.length, "Input mismatch");
    require(_phases.length == _assets.length, "Input mismatch");

    for (uint256 i = 0; i < _phases.length; i++) {
      phase2Asset[_phases[i]].minter = _minters[i];
      phase2Asset[_phases[i]].asset = _assets[i];
    }
  }

  function togglePauseTrading(uint256[] calldata _phases, bool[] calldata _status) external onlyOwner {
    require(_phases.length == _status.length, "Input mismatch");
    for (uint256 i = 0; i < _phases.length; i++) {
      phase2Asset[_phases[i]].trading_paused = _status[i];
    }
  }

  // verified
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /** Internal */
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _batchSize
  ) internal virtual override {
    bool tradingPaused = phase2Asset[token2Phase[_tokenId]].trading_paused;
    require(_from == address(0) || !tradingPaused, "Token paused");
    super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
  }
}