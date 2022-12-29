// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @custom:security-contact [email protected]
contract ThreeGateSubdomainsV2 is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    using Strings for uint256;
    // A map of expiry times
    mapping(uint256 => TokenData) public ensToTokenData;
    mapping(uint256 => uint256) public expiries;
    struct TokenData {
        uint256 created;
        uint256 expiration;
        uint256 registration;
        uint256 labelSize;
        string label;
    }
    // The ENS registry
    ENS public ens;
    address public resolver;

    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    string constant _START_SVG =
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%" viewBox="0 0 1000 1000"><defs><style>.cls-1 {opacity: 0;}.cls-1,.cls-3 {fill: url(#linear-gradient);}.cls-2 {clip-path: url(#clip-path);}.cls-4 {opacity: 0.316;fill: url(#linear-gradient-3);}.cls-5 {fill: rgba(38, 208, 124, 1);font-size: 56px;font-family: Arial-BoldMT, Arial;}.cls-5,.cls-7 {font-weight: 700;letter-spacing: -0.04em;}.cls-6 {fill: rgba(255, 255, 255, 0.6);font-size: 24px;}.cls-7,.cls-9 {fill: #fff;}.cls-7 {font-size: 32px;font-family: Gilroy-Bold, Gilroy;}.cls-8 {fill: #26d07c;}.cls-10 {opacity: 0.034;}.cls-11 {fill: #41b6e6;}</style><linearGradient id="linear-gradient" x1="0.014" x2="0.847" y2="1" gradientUnits="objectBoundingBox"><stop offset="0" stop-color="#1d252d" /><stop offset="1" stop-color="#2c4353" /></linearGradient><clipPath id="clip-path"><rect id="Rectangle_147" data-name="Rectangle 147" class="cls-1" width="1000" height="1000" /></clipPath><linearGradient id="linear-gradient-3" x1="0.006" x2="1" y2="1" gradientUnits="objectBoundingBox"><stop offset="0" /><stop offset="1" stop-opacity="0.231" /></linearGradient></defs><g id="_84d21f915c30c1a7530eabf93075fcb7_1_" data-name="84d21f915c30c1a7530eabf93075fcb7 (1)" transform="translate(0 32)"><g id="SVG_Sample_4" data-name="SVG Sample 4" class="cls-2" transform="translate(0 -32)"><rect id="Rectangle_146" data-name="Rectangle 146" class="cls-3" width="1000" height="1000" /><path id="Path_76" data-name="Path 76" class="cls-4" d="M0,0H1000V89H0Z" /></g><g id="_3Gate_logo" data-name="3Gate_logo" transform="translate(-231.664 -665.473)"><path id="Path_64" data-name="Path 64" class="cls-8" d="M-268.267-124.487l7.108-8.452V-142.8h-29.455v12.422H-277.1l-6.019,7.044,4.995,7.428h2.753c2.305,0,3.842.96,3.842,3.2,0,2.113-1.538,3.33-3.842,3.33-2.882,0-4.546-1.729-5.379-4.674l-11.269,6.466c2.625,7.172,9.029,10.629,16.649,10.629,8.965,0,16.649-4.74,16.649-15.112C-258.726-118.66-262.7-122.886-268.267-124.487Z" transform="translate(571 797.665)" /><path id="Path_65" data-name="Path 65" class="cls-9" d="M-128.928-122.019h-22.412v5.379h16.456c-1.153,6.723-6.659,11.846-15.945,11.846-10.693,0-17.8-7.684-17.8-17.417,0-9.8,7.172-17.481,17.546-17.481a16.061,16.061,0,0,1,14.345,8.067l5.123-3.01a22.362,22.362,0,0,0-19.4-10.822c-13.639,0-23.5,10.373-23.5,23.244,0,12.807,9.8,23.244,23.628,23.244,13.511,0,21.963-8.965,21.963-20.362ZM-93.9-99.8h6.341l-16.714-44.823H-111L-127.712-99.8h6.341l3.649-10.053h20.17Zm-21.771-15.624,8-22.091,8.067,22.091Zm53.019-29.2H-94.99v5.635H-81.8V-99.8h5.891v-39.188h13.255Zm11.719,39.188v-14.215h18.89v-5.571h-18.89v-13.767h20.491v-5.635H-56.891V-99.8h26.766v-5.635Z" transform="translate(490.379 800)" /></g><g><path id="text_path" pathLength="100" d="M 60,130 h 880 M 60,185 h 880 M 60,240 h 880 M 60,295 h 880 M 60,350 h 880 M 60,405 h 880 M 60,460 h 880 M 60,515 h 880 M 60,570 h 880 M 60,625 h 880 M 60,680 h 880 M 60,735 h 880 M 60,790 h 880 M 60,845 h 880 M 60,900 h 880" /><text class="cls-5" letter-spacing="5"><textPath startOffset="100%" text-anchor="end" dominant-baseline="bottom" xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="#text_path" letter-spacing="0.4">';
    string constant _END_SVG =
        '<tspan class="cls-6" y="0">.3gate.eth</tspan></textPath></text></g><g id="Group_321" data-name="Group 321" class="cls-10" transform="translate(12999.461 16894.637)"><path id="Subtraction_17" data-name="Subtraction 17" class="cls-11" d="M562.015,690.734h-345a44.388,44.388,0,0,1-38.408-22.245L5.87,367.4a44.285,44.285,0,0,1,0-44.066L178.611,22.246A44.391,44.391,0,0,1,217.019,0h345a44.387,44.387,0,0,1,38.4,22.246L773.159,323.335a44.289,44.289,0,0,1,0,44.066L600.418,668.49A44.384,44.384,0,0,1,562.015,690.734Zm-227.6-283.979h0L228.435,467.575a151.863,151.863,0,0,0,24.8,44.071,141.289,141.289,0,0,0,35.866,31.2A162.319,162.319,0,0,0,333.776,561.4,207.8,207.8,0,0,0,385,567.534a205.1,205.1,0,0,0,60.029-8.486c19.129-5.855,35.908-14.6,49.868-25.987a120.961,120.961,0,0,0,34.06-44.279c8.367-18.5,12.609-39.817,12.609-63.358a131.033,131.033,0,0,0-6.653-42.3A109.1,109.1,0,0,0,516.348,349.4a115.078,115.078,0,0,0-28.386-24.917,141.475,141.475,0,0,0-36.12-15.882l66.84-79.485V136.379h-277V253.2H368.743l-56.607,66.237,46.97,69.854H385c11.249,0,20.062,2.406,26.195,7.152,6.594,5.1,9.936,12.826,9.936,22.959,0,19.315-13.844,31.313-36.131,31.313-13.114,0-24.053-3.9-32.517-11.591-7.965-7.239-14.043-18.129-18.066-32.366Z" transform="translate(-12888.975 -16772.004)" /></g></g></svg>';
    address public signer;
    uint256 _totalSupply;
    string public startSvg;
    string public endSvg;
    address public bank;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __ERC721_init("3GATE Subdomains", "3GATEID");
        __Ownable_init();
        __UUPSUpgradeable_init();
        baseNode = 0xf03c3ff37b2b596feae20ffcd1906cc65a077ea62654cfec3ecd08f0ea492d57;
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        signer = 0xc5b0c020a0ab9e7f41E8297a40FF33CF21202ce9;
        bank = 0x72B1202c820e4B2F8ac9573188B638866C7D9274;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    modifier live() {
        require(ens.owner(baseNode) == address(this));
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (address)
    {
        require(expiries[tokenId] > block.timestamp);
        return super.ownerOf(tokenId);
    }

    function _getMessageHash(string memory label, address to)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _getMessage(label, to)
                )
            );
    }

    function _getMessage(string memory label, address to)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(to, label));
    }

    function recover(
        string memory label,
        address to,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 hash = _getMessageHash(label, to);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }

    function reclaimBaseNode() external onlyOwner {
        ens.setOwner(baseNode, owner());
    }

    function setBaseNode(bytes32 _baseNode) external onlyOwner {
        baseNode = _baseNode;
    }

    function setBank(address _bank) external onlyOwner {
        bank = _bank;
    }

    function setSvg(string calldata start, string calldata end)
        external
        onlyOwner
    {
        uint256 lenStart = bytes(start).length;
        uint256 lenEnd = bytes(end).length;
        if (lenStart == 0 && lenEnd == 0) revert();
        if (lenStart > 0) startSvg = start;
        if (lenEnd > 0) endSvg = end;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address _resolver) external onlyOwner {
        ens.setResolver(baseNode, _resolver);
        resolver = _resolver;
    }

    // Returns the expiration timestamp of the specified id.
    function nameExpires(uint256 id) external view returns (uint256) {
        return expiries[id];
    }

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view returns (bool) {
        // Not available if it's registered here or in its grace period.
        return expiries[id] < block.timestamp;
    }

    function register(address owner, bytes memory data) external payable {
        require(msg.value == 0.003 ether, "Wrong eth value");
        (string memory label, bytes memory signature) = abi.decode(
            data,
            (string, bytes)
        );
        require(recover(label, owner, signature), "wrong signature");
        bytes32 labelhash = keccak256(bytes(label));
        ensToTokenData[uint256(labelhash)].created = block.timestamp;
        ensToTokenData[uint256(labelhash)].labelSize = bytes(label).length;
        ensToTokenData[uint256(labelhash)].label = label;
        _register(uint256(labelhash), labelhash, owner, true);
        _totalSupply++;
    }

    function _register(
        uint256 id,
        bytes32 labelhash,
        address owner,
        bool updateRegistry
    ) internal live {
        require(available(id));

        expiries[id] = block.timestamp + type(uint64).max;
        if (_exists(id)) {
            // Name was previously owned, and expired
            _burn(id);
        }
        _mint(owner, id);
        if (updateRegistry) {
            ens.setSubnodeRecord(
                baseNode,
                labelhash,
                owner,
                resolver,
                type(uint64).max
            );
        }

        emit NameRegistered(id, owner, block.timestamp + type(uint64).max);
    }

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external live {
        require(_isApprovedOrOwner(msg.sender, id));
        ens.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function tokenURI(uint256 ensID)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(ensID), "ERC721: token doesn't exist");
        string memory svg = Base64.encode(
            abi.encodePacked(startSvg, ensToTokenData[ensID].label, endSvg)
        );
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"description":"',
                ensToTokenData[ensID].label,
                ' is a 3GATE.eth subdomain registered for FREE at 3gate.io. 3GATE, Token-gate EVERYTHING.","external_url":"3gate.io.","name":"',
                ensToTokenData[ensID].label,
                '","animation_url":"http://3.quantum.tech/3gate/',
                ensToTokenData[ensID].label,
                '","image":"data:image/svg+xml;base64,',
                svg,
                '","attributes":[{"display_type":"date","trait_type": "Created Date","value":"',
                ensToTokenData[ensID].created.toString(),
                '"},{"display_type":"number","trait_type": "Length","value":"',
                ensToTokenData[ensID].labelSize.toString(),
                '"}]}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function withdraw() public onlyOwner {
        payable(bank).transfer(address(this).balance);
    }
}