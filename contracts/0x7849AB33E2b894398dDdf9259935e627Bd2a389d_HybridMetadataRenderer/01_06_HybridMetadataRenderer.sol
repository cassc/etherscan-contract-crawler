// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import "@openzeppelin/contracts/utils/Strings.sol";
import './IMetadataRenderer.sol';

/**
 * A Metadata Renderer with on-chain metadata interpolation and off-chain SVG rendering
 */
contract HybridMetadataRenderer is Ownable, IMetadataRenderer {
  string public svgRenderingURI;

  constructor(string memory _svgRenderingURI) Ownable() {
    svgRenderingURI = _svgRenderingURI;
  }

  function setSvgRenderingURI(string memory _svgRenderingURI) public onlyOwner {
    svgRenderingURI = _svgRenderingURI;
  }

  function renderName(Metadata memory metadata) internal pure returns (string memory nameStr) {
    if(metadata.bannerType == BannerType.FOUNDER) {
      nameStr = string(abi.encodePacked('#', Strings.toString(metadata.tokenId), ': Founders Ticket'));
    } else if(metadata.bannerType == BannerType.EXCLUSIVE) {
      nameStr = string(abi.encodePacked('#', Strings.toString(metadata.tokenId), ': Exclusive Pods'));
    } else if(metadata.bannerType == BannerType.PRIME) {
      nameStr = string(abi.encodePacked('#', Strings.toString(metadata.tokenId), ': Prime Teleporter'));
    } else if(metadata.bannerType == BannerType.REPLICANT) {
      nameStr = string(abi.encodePacked('#', Strings.toString(metadata.tokenId), ': Replicant Trait Withdrawal Pods'));
    } else if(metadata.bannerType == BannerType.SECRET) {
      nameStr = string(abi.encodePacked('#', Strings.toString(metadata.tokenId), ': Secret OBR Rare'));
    } else {
      revert();
    }
  }

  function renderDescription(Metadata memory metadata) internal pure returns (string memory descriptionString) {
    if(metadata.bannerType == BannerType.FOUNDER) {
      descriptionString = string(abi.encodePacked('Avastar Memory Banner, Founder, #', Strings.toString(metadata.avastarId), ', Founders Ticket, Original Art by [Marmota vs Milky](https://www.twine.fm/marmotavsmilky)'));
    } else if(metadata.bannerType == BannerType.EXCLUSIVE) {
      descriptionString = string(abi.encodePacked('Avastar Memory Banner, Exclusive, #', Strings.toString(metadata.avastarId), ', Exclusive Pods, Portrait ', renderAvastarImageValue(metadata) ,', Original Art by [Marmota vs Milky](https://www.twine.fm/marmotavsmilky)'));
    } else if(metadata.bannerType == BannerType.PRIME) {
      descriptionString = string(abi.encodePacked('Avastar Memory Banner, Prime, #', Strings.toString(metadata.avastarId), ', Prime Teleporter, Background ', renderBGValue(metadata),', Original Art by [Marmota vs Milky](https://www.twine.fm/marmotavsmilky)'));
    } else if(metadata.bannerType == BannerType.REPLICANT) {
      descriptionString = string(abi.encodePacked('Avastar Memory Banner, Replicant, #', Strings.toString(metadata.avastarId), ', Replicant Trait Withdrawal Pods, Background ', renderBGValue(metadata),', Original Art by [Marmota vs Milky](https://www.twine.fm/marmotavsmilky)'));
    } else if(metadata.bannerType == BannerType.SECRET) {
      descriptionString = string(abi.encodePacked('Avastar Memory Banner, Secret OBR Rare, Original Art by [Marmota vs Milky](https://www.twine.fm/marmotavsmilky)'));
    } else {
      revert();
    }
  }

  function renderImage(Metadata memory metadata) internal view returns (string memory imageStr) {
    imageStr = string(abi.encodePacked(svgRenderingURI, '/type/', Strings.toString(uint256(metadata.bannerType)), '/bg/', Strings.toString(uint256(metadata.backgroundType)), '/avastar/', Strings.toString(metadata.avastarId), '/', Strings.toString(uint256(metadata.avastarImageType)) ));
  }

  function renderBGValue(Metadata memory metadata) internal pure returns (string memory bgValueStr) {
    require(metadata.backgroundType != BackgroundType.INVALID);
    if(metadata.bannerType == BannerType.PRIME) {
      require(uint(metadata.backgroundType) < uint(BackgroundType.R1));
      bgValueStr = string(abi.encodePacked('P', Strings.toString(uint(metadata.backgroundType) - uint(BackgroundType.P1) + 1)));
    } else if(metadata.bannerType == BannerType.REPLICANT) {
      require(uint(metadata.backgroundType) >= uint(BackgroundType.R1));
      bgValueStr = string(abi.encodePacked('R', Strings.toString(uint(metadata.backgroundType) - uint(BackgroundType.R1) + 1)));
    } else {
      revert();
    }
  }

  function renderAvastarImageValue(Metadata memory metadata) internal pure returns (string memory avastarImageValueStr) {
    require(metadata.avastarImageType != AvastarImageType.INVALID);
    if (metadata.avastarImageType == AvastarImageType.PRISTINE) {
      avastarImageValueStr = 'Pristine';
    } else if (metadata.avastarImageType == AvastarImageType.STYLED) {
      avastarImageValueStr = 'Styled';
    }

  }

  function renderAttributes(Metadata memory metadata) internal pure returns (string memory attributeStr) {
    if(metadata.bannerType == BannerType.FOUNDER) {
      attributeStr = string(abi.encodePacked('{"trait_type":"Type","value":"Founders Ticket"}'));
    } else if(metadata.bannerType == BannerType.EXCLUSIVE) {
      attributeStr = string(abi.encodePacked('{"trait_type":"Type","value":"Exclusive Pods"},{"trait_type":"Avastar Image","value":"',renderAvastarImageValue(metadata),'"}'));
    } else if(metadata.bannerType == BannerType.PRIME) {
      attributeStr = string(abi.encodePacked('{"trait_type":"Type","value":"Prime Teleporter"},{"trait_type":"Wave","value":"Prime"},{"trait_type":"BG Color","value":"',renderBGValue(metadata),'"}'));
    } else if(metadata.bannerType == BannerType.REPLICANT) {
      attributeStr = string(abi.encodePacked('{"trait_type":"Type","value":"Replicant Trait Withdrawal Pods"},{"trait_type":"Wave","value":"Replicant"},{"trait_type":"BG Color","value":"',renderBGValue(metadata),'"}'));
    } else if(metadata.bannerType == BannerType.SECRET) {
      attributeStr = string(abi.encodePacked('{"trait_type":"Type","value":"Secret OBR Rare"}'));
    } else {
      revert();
    }
  }

  function renderMetadataString(Metadata memory metadata) internal view returns (string memory metadataStr) {
    metadataStr = string(abi.encodePacked(
      '{"name":"', renderName(metadata) ,'","description":"',renderDescription(metadata),'","image":"',renderImage(metadata),'","attributes":[',renderAttributes(metadata),']}'
    ));
  }

  function renderMetadata(Metadata memory metadata) external view returns (string memory metadataStr) {
    return renderMetadataString(metadata);
  }

  function renderTokenURI(Metadata memory metadata) external view returns (string memory tokenURI) {
    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(renderMetadataString(metadata)))
    ));
  }
}