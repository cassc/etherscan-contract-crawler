// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IStarMetadata.sol";
import "./IStarName.sol";
import "./IStar.sol";

contract StarMetadata is IStarMetadata, AdminControl {
    using Strings for uint256;

    // Star type to star default min and max LVMINANCE values
    mapping(uint8 => StarLvminance) public lvminanceRangeLookup;
    // Star type to star image URL
    mapping(uint8 => string) public imageURLLookup;
    // Contract with default & overriden Star name data
    address private _starNameLookup;

    constructor(address starNameLookup) {
        _starNameLookup = starNameLookup;

        lvminanceRangeLookup[uint8(1)] = StarLvminance(5, 15);
        imageURLLookup[uint8(1)] = 'https://arweave.net/O_sPATDPYba2igM9n3D-_1RiyWlWi3kLrbkQG4IaXbc';

        lvminanceRangeLookup[uint8(2)] = StarLvminance(5, 15);
        imageURLLookup[uint8(2)] = 'https://arweave.net/DZz8l1fWQqYRmD2Oaba9H0R_1TxG4FqNj9ckyXN9l8E';

        lvminanceRangeLookup[uint8(3)] = StarLvminance(20, 40);
        imageURLLookup[uint8(3)] = 'https://arweave.net/_pl8SDCRE48XXDDFbUmuGhXPy96rtDm0TE__uCO5sWo';

        lvminanceRangeLookup[uint8(4)] = StarLvminance(20, 40);
        imageURLLookup[uint8(4)] = 'https://arweave.net/n0FnfWaTiEKV5ZJoOXXgrD3BP9uJE8t6idwd6a6GdCA';

        lvminanceRangeLookup[uint8(5)] = StarLvminance(20, 40);
        imageURLLookup[uint8(5)] = 'https://arweave.net/mg-lcjcS5UAMZbGDAmz7Rtb0mCeJacvJYy6jtgUAEuk';

        lvminanceRangeLookup[uint8(6)] = StarLvminance(50, 150);
        imageURLLookup[uint8(6)] = 'https://arweave.net/ZHqYjv3AMxyr260hBMxiQnFh9qB9ZUmXBoI57u2gOMc';

        lvminanceRangeLookup[uint8(7)] = StarLvminance(50, 150);
        imageURLLookup[uint8(7)] = 'https://arweave.net/s_SqCL_YIm3oXD0b7f7kJPPCpyhC410hlx2XnPfZp-I';

        lvminanceRangeLookup[uint8(8)] = StarLvminance(200, 400);
        imageURLLookup[uint8(8)] = 'https://arweave.net/b7DD1rCSSox6B6MARhXTcJ5JijIwlJkjVWE2WZBSW9o';

        lvminanceRangeLookup[uint8(9)] = StarLvminance(200, 400);
        imageURLLookup[uint8(9)] = 'https://arweave.net/S7dJmBAY7PZHF3gspDVI5QfnyD8U58MZmaTlBofcdMk';

        lvminanceRangeLookup[uint8(10)] = StarLvminance(500, 1000);
        imageURLLookup[uint8(10)] = 'https://arweave.net/6QHAUwMHwyTnXKrm-jhIJEzUCRJ-ewSSv0n7TyVmu9U';

        lvminanceRangeLookup[uint8(11)] = StarLvminance(1500, 2500);
        imageURLLookup[uint8(11)] = 'https://arweave.net/T2ExZqLQyDi5yXtqJlgfyfKzENVLvQfmJMM5DrrLibE';

        lvminanceRangeLookup[uint8(12)] = StarLvminance(5000, 5000);
        imageURLLookup[uint8(12)] = 'https://arweave.net/frOcoUkOl2-rkZjFbpKUn8JXr-hsdbs45QUSihvktMU';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AdminControl) returns (bool) {
        return
            interfaceId == type(IStarMetadata).interfaceId ||
            interfaceId == type(AdminControl).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IStarMetadata-setName}.
     */
    function setName(uint256 tokenId, string memory name) public override {
        IStarName(_starNameLookup).setOverride(tokenId, name);
    }

    /**
     * @dev See {IStarMetadata-updateStarNameLookup}.
     */
    function updateStarNameLookup(address starNameLookup) public override adminRequired {
        _starNameLookup = starNameLookup;
    }

    /**
     * @dev See {IStarMetadata-updateStar}.
     */
    function updateStar(uint8 starType, string memory url, uint16 min, uint16 max) public override adminRequired {
        imageURLLookup[starType] = url;
        lvminanceRangeLookup[starType] = StarLvminance(min, max);
    }

    /**
     * @dev See {IStarMetadata-metadata}.
     */
    function metadata(uint256 tokenId, IStar.StarInfo memory starInfo) public view virtual override returns (string memory) {
        // classic modulo approach to selecting from a min-max integer range
        uint256 lvminance = (
            uint256(keccak256(
            // TODO: add in starInfo.starTime on production
              abi.encodePacked(tokenId, starInfo.starType, starInfo.creator) // pRNG
            ))
            % (lvminanceRangeLookup[starInfo.starType].max - lvminanceRangeLookup[starInfo.starType].min)
            + lvminanceRangeLookup[starInfo.starType].min
        );

        return string(abi.encodePacked('data:application/json;utf8,',
            '{"name":"', IStarName(_starNameLookup).getName(tokenId, starInfo),
            '","created_by":"LVCIDIA","description":"The%20FIRST%20ERA%20has%20begun%2C%20and%20it%20appears%20that%20the%20stars%20of%20LVCIDIA%20have%20faded...The%20explorers%20of%20LVCIDIA%20need%20to%20come%20together%20to%20return%20these%20stars%20to%20their%20former%20splendour%2C%20paving%20the%20way%20to%20a%20new%20galaxy%20with%20new%20planets%20in%20the%20process.%5CnHarness%20the%20power%20of%20your%20NFTs%20with%20staking%20and%20help%20us%20build%20LVCIDIA%20one%20step%20at%20a%20time.%20In%20exchange%2C%20your%20name%20will%20forever%20be%20seen%20in%20the%20sky%20of%20LVCIDIA.',
            '","image_url":"', imageURLLookup[starInfo.starType],
            '","attributes":[',
              '{"trait_type":"Type","value":"',  IStarName(_starNameLookup).getDefaultName(starInfo.starType), '"},',
              '{"trait_type":"LVMINANCE","value":"', lvminance.toString(), '"},',
              '{"trait_type":"Artist","value":"LVCIDIA"},',
              '{"trait_type":"Staking%20Era","value":"First%20Era"},',
              '{"trait_type":"Galaxy","value":"FV_T77%2F%2F"},',
              '{"trait_type":"Coordinates","value":"X%3D0.000%20Y%3D0.000%20Z%3D0.000"},',
              '{"trait_type":"Creation%20Date","value":"',  uint256(starInfo.starTime).toString(), '"},'
              '{"trait_type":"Named","value":"', IStarName(_starNameLookup).isOverriden(tokenId) ? 'Yes' : 'No', '"}',
            ']}'
        ));
    }
}