// SPDX-License-Identifier: MIT

/*
 * Created by Isamu Arimoto (@isamua)
 */

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import './libs/ProviderTokenA1.sol';

contract LuToken is ProviderTokenA1 {
  using Strings for uint256;

  // lu committee
  address public committee;

  constructor(
    IAssetProvider _assetProvider,
    address _committee
  ) ProviderTokenA1(_assetProvider, 'Laidback Lu', 'Laidback Lu') {
    description = 'Laidback Lu.';
    mintPrice = 1e16;
    mintLimit = 440;
    committee = _committee;

    _safeMint(address(0x1A474Bd77F8109078CCdEf5896f499642830f3CA), 20);
    _safeMint(address(0x4E4cD175f812f1Ba784a69C1f8AC8dAa52AD7e2B), 20);
    _safeMint(address(0x818Fb9d440968dB9fCB06EEF53C7734Ad70f6F0e), 20);
    _safeMint(address(0x56BB106d2Cc0a1209De6962a49634321AD0d9082), 10);
    _safeMint(address(0x49b7045B25d3F8B27F9b75E60484668327D96897), 5);
    _safeMint(address(0xedFEF30eaBef62C9Bf55121B407cA1B3Fde7F529), 5);
    

  }

  function tokenName(uint256 _tokenId) internal pure override returns (string memory) {
    return string(abi.encodePacked('Laidback Lu ', _tokenId.toString()));
  }

  function mint() public payable virtual override returns (uint256 tokenId) {
      require(msg.value >= mintPrice, 'Must send the mint price');
      
      address payable payableTo = payable(committee);
      payableTo.transfer(address(this).balance);

      return super.mint();
  }
}