//SPDX-License-Identifier: MIT
/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     (@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(   @@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@             @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@@(            @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@(         @@(         @@(            @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@          @@          @@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(     @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @           @           @@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(            @@@         @@@         @@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@             @@@@@@@     @@@@@@@     @@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@             @@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@(            @@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@(            @@@@@@@@@@@@@@@@@@@@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@(     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 */
pragma solidity 0.8.6;

import "./AbstractStaking.sol";
import "./interfaces/IN.sol";
import "./interfaces/INil.sol";
import "./interfaces/INOwnerResolver.sol";
import "./libraries/NilProtocolUtils.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title StakedN
 * @author Nil DAO
 */
contract StakedN is AbstractStaking, ERC721Holder, INOwnerResolver, ERC721Enumerable {
    using Strings for uint256;

    uint256 public constant N_UNIT = 1e18;
    uint256 public constant N_SUPPLY = 8888;
    uint256 public constant INVERSE_N_SHARE_OF_NIL = 4;
    uint256 public constant VOTE_DENOMINATOR = 1;
    IN public immutable n;

    constructor(
        INil nil_,
        IN n_,
        address dao,
        uint256 rewardRatePerSecond,
        uint256 votesRatePerSecond
    ) AbstractStaking(nil_, dao, rewardRatePerSecond, votesRatePerSecond) ERC721("Staked n", "STN") {
        require(address(n_) != address(0), "StakedN:ILLEGAL_ADDRESS");
        n = n_;
    }

    function stake(uint256[] calldata nIds) external nonReentrant {
        for (uint256 i = 0; i < nIds.length; i++) {
            n.safeTransferFrom(msg.sender, address(this), nIds[i]);
            _mint(msg.sender, nIds[i]);
        }
        _stake(msg.sender, nIds.length * N_UNIT);
    }

    function unstake(uint256[] calldata nIds) external nonReentrant {
        _unstake(msg.sender, nIds.length * N_UNIT);
        for (uint256 i = 0; i < nIds.length; i++) {
            require(ownerOf(nIds[i]) == msg.sender, "StakedN:WRONG_OWNER");
            _burn(nIds[i]);
            n.safeTransferFrom(address(this), msg.sender, nIds[i]);
        }
    }

    function nOwned(address owner) external view override returns (uint256[] memory nids) {
        uint256 balance = balanceOf(owner);
        nids = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            nids[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    function ownerOf(uint256 nid) public view override(INOwnerResolver, ERC721) returns (address) {
        return super.ownerOf(nid);
    }

    function balanceOf(address account) public view override(INOwnerResolver, ERC721) returns (uint256) {
        return super.balanceOf(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual override {
        //Allow only mint and burn
        require(from == address(0) || to == address(0), "StakedN:TRANSFER_DENIED");
        super._beforeTokenTransfer(from, to, id);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return n.getFirst(tokenId);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return n.getSecond(tokenId);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return n.getThird(tokenId);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return n.getFourth(tokenId);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return n.getFifth(tokenId);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return n.getSixth(tokenId);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return n.getSeventh(tokenId);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return n.getEight(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>c1{stroke:#231f20;stroke-miterlimit:10;}c2{fill:#fff;}</style><rect class="cls-1" x="0.5" y="0.5" width="350" height="350"></rect><rect class="cls-2" x="182.734" y="129.922" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -45.581875, 186.4375)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="182.734" y="182.734" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -82.925415, 201.906036)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="235.545" y="182.734" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -67.456871, 239.248123)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="182.734" y="235.547" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -120.267502, 217.373123)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="129.924" y="129.922" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -61.050415, 149.093964)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="129.924" y="77.112" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -23.706875, 133.626877)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="77.112" y="129.922" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -76.517502, 111.751877)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="209.14" y="103.516" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -19.175833, 197.375)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="235.545" y="77.112" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, 7.22875, 208.3125)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="261.95" y="50.706" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, 33.634792, 219.25)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="50.706" y="261.949" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -177.609161, 131.75)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="77.112" y="235.547" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -151.20459, 142.6875)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="103.517" y="209.14" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -124.798538, 153.625)" style="fill: rgb(51, 51, 51);"></rect><rect class="cls-2" x="129.924" y="182.734" width="37.344" height="37.344" transform="matrix(0.707108, -0.707106, 0.707107, 0.707107, -98.392502, 164.5625)" style="fill: rgb(51, 51, 51);"></rect><text style="fill: rgb(255, 255, 255); font-family: serif, sans-serif; font-size: 6px; white-space: pre;" x="254.873" y="294.774" transform="matrix(1.166667, 0, 0, 1.166667, -0.083333, -0.083333)">';

        parts[1] = NilProtocolUtils.stringify(n.getFirst(tokenId));

        parts[2] = " ";

        parts[3] = NilProtocolUtils.stringify(n.getSecond(tokenId));

        parts[4] = " ";

        parts[5] = NilProtocolUtils.stringify(n.getThird(tokenId));

        parts[6] = " ";

        parts[7] = NilProtocolUtils.stringify(n.getFourth(tokenId));

        parts[8] = " ";

        parts[9] = NilProtocolUtils.stringify(n.getFifth(tokenId));

        parts[10] = " ";

        parts[11] = NilProtocolUtils.stringify(n.getSixth(tokenId));

        parts[12] = " ";

        parts[13] = NilProtocolUtils.stringify(n.getSeventh(tokenId));

        parts[14] = " ";

        parts[15] = NilProtocolUtils.stringify(n.getEight(tokenId));

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        string memory json = NilProtocolUtils.base64encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "sN #',
                        NilProtocolUtils.stringify(tokenId),
                        '", "description": "Staked N is just staked numbers.", "image": "data:image/svg+xml;base64,',
                        NilProtocolUtils.base64encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }
}