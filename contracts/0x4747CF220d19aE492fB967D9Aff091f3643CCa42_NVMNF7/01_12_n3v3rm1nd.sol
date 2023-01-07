/**
 * @dev https://twitter.com/NVMNF7
 * @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 * @@@@@@@@@&PJJ5?^^!!!J#@@@@@@@@@
 * @@@@@@GJ?^           .^[email protected]@@@@@@
 * @@@@G?                 ^P&@@@@@
 * @@@5                     [email protected]@@@@
 * @@@5~   :.:!~~!~^~:      [email protected]@@@@
 * @@@@@G^!7~~7J!~~!JJ!    J&@@@@@
 * @@@@@@7!!777^[email protected]@@@@@@
 * @@@@@[email protected]!!G##??JJ?!7^[email protected]@@@@@
 * @@@@@[email protected]@@@@@@
 * @@@@@&7!?JJJJ!^[email protected]@@@@
 * @@@@@@@Y^~!7?77777^[email protected]@@@
 * @@@@&#J!!!^^^~^!7J?5P555PY^&@@@
 * @@BJ7~~!~^?PJJ!JYYPP55555P^[email protected]@@
 */

// SPDX-License-Identifier: MIT

/**
 * @dev Redployed contract
 */
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";
import "./vrf.sol";

contract NVMNF7 is ERC721A, Ownable, VRFv2DirectFundingConsumer {
    constructor() ERC721A("N3V3RM1ND", "N3V3RM1ND") {
        c0nf16 = C0nf16(3, 3310, 2, 0, 1, false, true);
    }

    C0nf16 public c0nf16;
    string public r3v34l3dur1;
    uint256 private _734mr353rv3;

    struct C0nf16 {
        uint256 m4xm1n7ph453;
        uint256 m4x5upply;
        uint256 m4xm1n7;
        uint256 pr1c3;
        uint256 ph453;
        bool r3v34l;
        bool publ1cm0d3;
    }

    /**
     * @dev Only winner(m1n73l161bl3) generated onchain can mint if the public mode is off.
     */
    function purch453(uint256 num) external payable {
        require(c0nf16.ph453 > 0, "n07 1n m1n7 ph453.");
        require(num * c0nf16.pr1c3 <= msg.value, "n0 3n0u6h 37h.");
        require(
            numb3rm1n73d(msg.sender) + num <= c0nf16.m4xm1n7,
            "3xc33d m4xm1um m1n7."
        );
        require(
            totalSupply() + num <= m4xm1n70fph453(),
            "4ll 70k3n m1n73d 1n 7h15 ph453."
        );

        if (c0nf16.publ1cm0d3 == false) {
            require(m1n73l161bl3(msg.sender), "n0 3l161bl3");
        }

        _safeMint(msg.sender, num);
    }

    /**
     * @dev Generate winner onchain (Check a address is eligible to mint at phase).
     */
    function m1n73l161bl3(address _4ddr355) public view returns (bool) {
        require(!c0nf16.r3v34l, "m1n7 15 n07 l1v3.");
        uint256 seed = uint256(
            keccak256(abi.encodePacked(_4ddr355, curr3n7h45h()))
        ) % 2;

        return (seed == 0);
    }

    /**
     * @dev Override tokenURI and shuffle all ids if revealed.
     */
    function tokenURI(uint256 _1d)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        require(_1d > 0 && _1d <= totalSupply(), "1nv4l1d 70k3n.");

        return
            c0nf16.r3v34l
                ? string(abi.encodePacked(r3v34l3dur1, r3v34l3d1d(_1d)))
                : unr3v34l();
    }

    /**
     * @dev Unreveal metadata.
     */
    function unr3v34l() private pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"description": "d0 7h3 m057 w17h 7h3 l3457 3ff0r7","image":"ipfs://bafybeic2aw2ibct2o7lyjiqjqxz2ot6i5vwk4i5gjk3qjsogby5i6m2h2q"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Fetch current phase hash.
     */
    function curr3n7h45h() public view returns (uint256) {
        require(h45h.length > 0, "1nv4l1d h45h");

        if (c0nf16.r3v34l) {
            return h45h[c0nf16.m4xm1n7ph453];
        } else {
            return h45h[c0nf16.ph453 - 1];
        }
    }

    /**
     * @dev Get all max mint of phase.
     */
    function m4xm1n70fph453() public view returns (uint256) {
        if (c0nf16.ph453 == c0nf16.m4xm1n7ph453) {
            return c0nf16.m4x5upply;
        } else {
            uint256 _5l1c3 = c0nf16.m4x5upply / c0nf16.m4xm1n7ph453;
            return _5l1c3 * c0nf16.ph453;
        }
    }

    /**
     * @dev Shuffled ids.
     */
    function r3v34l3d1d(uint256 _1d) private view returns (string memory) {
        uint256 m4x5upply = c0nf16.m4x5upply;
        uint256[] memory m374d474 = new uint256[](m4x5upply + 1);

        for (uint256 i = 1; i <= m4x5upply; i += 1) {
            m374d474[i] = i;
        }

        for (uint256 i = 1; i <= m4x5upply; i += 1) {
            uint256 j = (uint256(keccak256(abi.encode(curr3n7h45h(), i))) %
                (m4x5upply)) + 1;

            (m374d474[i], m374d474[j]) = (m374d474[j], m374d474[i]);
        }

        return Strings.toString(m374d474[_1d]);
    }

    /**
     * @dev Team reserve 31 tokens.
     */
    function r353rv3(uint256 _r353rv3) external onlyOwner {
        require(_734mr353rv3 + _r353rv3 <= 31, "m1n73d");

        _734mr353rv3 += _r353rv3;
        _safeMint(msg.sender, _r353rv3);
    }

    /**
     * @dev Get address minted.
     */
    function numb3rm1n73d(address _addr) public view returns (uint256) {
        return _numberMinted(_addr);
    }

    /**
     * @dev Enter next phase and update price.
     */
    function n3x7ph453(uint256 pr1c3, bool publ1cm0d3) external onlyOwner {
        require(c0nf16.ph453 < c0nf16.m4xm1n7ph453);
        require(h45h.length > 0, "1nv4l1d h45h");
        c0nf16.publ1cm0d3 = publ1cm0d3;
        c0nf16.pr1c3 = pr1c3;
        c0nf16.ph453++;
    }

    /**
     * @dev Reveal all tokens.
     */
    function r3v34l4ll(string calldata _r3v34l3dur1) external onlyOwner {
        c0nf16.r3v34l = true;
        r3v34l3dur1 = _r3v34l3dur1;
    }

    /**
     * @dev Cut max supply.
     */
    function cu7m4x5upply(uint256 m4x) external onlyOwner {
        require(!c0nf16.r3v34l, "un4bl3 70 c4ll");
        require(m4x <= c0nf16.m4x5upply, "1nv4l1d.");
        c0nf16.m4x5upply = m4x;
    }

    /**
     * @dev Request a random number from VRF and should not call this function after token revealed.
     */
    function r3qu357h45h() external onlyOwner {
        require(!h45hr3qu3573d, "4lr34dy r3qu357.");
        _requestRandomWords();
    }

    /**
     * @dev Release contract eth balance.
     */
    function r3l3453() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "un4bl3 70 r3l3453");
    }

    /**
     * @dev Release contract link balance.
     */
    function r3l3453l1nk() external onlyOwner {
        _withdrawLink();
    }

    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }
}