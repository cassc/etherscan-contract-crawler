// SPDX-License-Identifier: MIT


import "./URIDependencies.sol";

pragma solidity ^0.8.17;


interface IMMO {
  function contributors() external view returns (uint256);
  function ending() external view returns (uint256);
  function currentWeek() external view returns (uint256);
  function settlementAddressProposals(uint256) external view returns (address);
  function votes(uint256, uint256) external view returns (bool);
  function ownerOf(uint256) external view returns (address);
}

contract MMOTokenURI {
  using Strings for uint256;

  IMMO public MMO;

  string public externalURL = 'https://steviep.xyz/moneymakingopportunity';

  constructor (address mmo) {
    MMO = IMMO(mmo);
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(tokenId < MMO.contributors(), 'Token ID out of bounds');

    bytes memory encodedSVG = abi.encodePacked(
      'data:image/svg+xml;base64,',
      Base64.encode(rawSVG(tokenId))
    );

    uint256 contributors = MMO.contributors();
    uint256 week = contributors - tokenId;

    bytes memory tokenName = abi.encodePacked(
      '"Money Making Opportunity #',
      tokenId.toString(),
      ' (Week ',
      week.toString(),
      '/',
      contributors.toString(),
      ')"'
    );

    bytes memory description = abi.encodePacked(
      '"',
      'Money Making Opportunity (MMO) is a smart contract-based collaboration game in which ',
      contributors.toString(),
      " participants send 0.03 ETH to the MMO contract, and must then negotiate and coordinate to distribute the resulting contract balance. MMO is inspired by the Pirate Game: a leader proposes a destination for the contract's balance; participants vote on the proposal; if the proposal is rejected, the leader is eliminated and may no longer vote on proposals. For more information, visit => ",
      externalURL,
      '"'
    );

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name":', tokenName,
      ',"description":', description,
      ',"license":"CCO"',
      ',"external_url":"', externalURL, '"'
      ',"attributes":', attributes(tokenId),
      ',"image":"', encodedSVG,
      '"}'
    );
    return string(json);
  }

  function generateStyle(uint256 tokenId) private view returns (bytes memory) {
    uint256 size = MMO.contributors();

    string memory deg1 = string(abi.encodePacked(
      'calc(', tokenId.toString(), 'turn/', size.toString(), ')'
    ));
    string memory deg2 = string(abi.encodePacked(
      'calc((0.5turn + (', tokenId.toString(), 'turn/', size.toString(), ')))'
    ));

    return abi.encodePacked(
      '<style>text{font:bold 50px sans-serif;fill:hsl(',
      deg1,
      ',100%,50%);text-anchor:middle}rect,line,circle{fill:none;stroke: hsl(',
      deg1,
      ',100%,50%);stroke-width:7.5px}.bg{fill:hsl(',
      deg2,
      ',100%,50%);stroke:none}</style>'
    );
  }

  function rawSVG(uint256 tokenId) public view returns (bytes memory) {
    string memory svg0 = '<svg viewBox="0 0 1000 1000" xmlns="http://www.w3.org/2000/svg">';
    string memory svg1 = '<rect x="0" y="0" width="1000" height="1000" class="bg"></rect><rect x="200" y="200" width="600" height="600" class="line"></rect><text x="500" y="915">MONEY MAKING OPPORTUNITY</text><text x="500" y="115">MONEY MAKING OPPORTUNITY</text>';
    string memory svg2 = '</svg>';

    uint256 week = MMO.contributors() - tokenId;
    uint256 currentWeek = MMO.currentWeek();

    string memory line1 = MMO.settlementAddressProposals(week) != address(0)
      ? '<line x1="200" y1="200" x2="800" y2="800" class="line"></line>'
      : '';

    string memory line2 = MMO.ending() > 0 && currentWeek == week
      ? '<line x1="800" y1="200" x2="200" y2="800" class="line"></line>'
      : '';


    string memory dollars = MMO.ending() > 0 && MMO.votes(tokenId, currentWeek)
      ?'<text x="500" y="670">$</text><text x="500" y="360">$</text><text x="350" y="515">$</text><text x="650" y="515">$</text>'
      : '';

    return abi.encodePacked(
      svg0,
      generateStyle(tokenId),
      svg1,
      line1,
      line2,
      dollars,
      svg2
    );
  }



  function attributes(uint256 tokenId) public view returns (bytes memory) {
    uint256 week = MMO.contributors() - tokenId;
    uint256 currentWeek = MMO.currentWeek();
    address settlementAddr = MMO.settlementAddressProposals(week);

    bytes memory settlementAddrProp = abi.encodePacked(
      '{"trait_type": "Proposed Settlement Address", "value": "',
      settlementAddr != address(0) ? Strings.toHexString(uint256(uint160(settlementAddr)), 20) : 'None',
      '"},'
    );

    bytes memory successfulVote = MMO.ending() > 0
      ? abi.encodePacked(
          '{"trait_type": "Successful Settlement Vote", "value": "',
          MMO.votes(tokenId, currentWeek) ? 'True' : 'False',
          '"},'
        )
      : abi.encodePacked('');

    bytes memory tokenIdProp = abi.encodePacked(
      '{"trait_type": "Opportunity ID", "value": "',
      tokenId.toString(),
      '"},'
    );

    bytes memory weekProp = abi.encodePacked(
      '{"trait_type": "Leadership Week", "value": "',
      week.toString(),
      '"}'
    );

    return abi.encodePacked('[', settlementAddrProp, successfulVote, tokenIdProp, weekProp, ']');
  }

  function updateExternalURL(string memory _externalURL) external {
    require(MMO.ownerOf(0) == msg.sender);
    externalURL = _externalURL;
  }
}
