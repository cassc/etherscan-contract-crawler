pragma solidity >=0.8.4;

import "./ENS.sol";
import "./PublicResolver.sol";
import "./IPRegistrarController.sol";
import "solady/src/utils/Base64.sol";
import "solady/src/utils/DynamicBufferLib.sol";
import "solady/src/utils/LibString.sol";
import "solady/src/utils/SSTORE2.sol";

import "./BokkyPooBahsDateTimeLibrary.sol";

import "hardhat/console.sol";

contract IPTokenRenderer is Ownable {
    using DynamicBufferLib for DynamicBufferLib.DynamicBuffer;
    using LibString for *;
    
    IPRegistrarController public immutable controller;
    BaseRegistrar public immutable base;
    
    string public tokenImageBaseUrl = "https://token-image.vercel.app/api";
    string public tokenBackgroundImageBaseURL = "https://ipfs.io/ipfs/";
    
    ENS public ethEns = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    ReverseRegistrar public ethReverseResolver;
    
    function addressToEthName(address addr) public view returns (string memory) {
        bytes32 node = ethReverseResolver.node(addr);
        address resolverAddr = ethEns.resolver(node);
        
        if (resolverAddr == address(0)) return addr.toHexStringChecksumed();
        
        string memory name = PublicResolver(resolverAddr).name(node);
        
        bytes32 tldNode = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes("eth"))));
        
        bytes32 forwardNode = controller._makeNode(tldNode, keccak256(bytes(name.split(".")[0])));
        
        address forwardResolver = ethEns.resolver(forwardNode);
        
        if (forwardResolver == address(0)) return addr.toHexStringChecksumed();
        
        address resolved = PublicResolver(forwardResolver).addr(forwardNode);
        
        if (resolved == addr) {
            return name;
        } else {
            return addr.toHexStringChecksumed();
        }
    }

    constructor(
        BaseRegistrar _base,
        IPRegistrarController _controller
    ) {
        base = _base;
        controller = _controller;
        
        address reverseEthRegAddress = block.chainid == 5 ?
            0xD5610A08E370051a01fdfe4bB3ddf5270af1aA48 :
            0x084b1c3C81545d370f3634392De611CaaBFf8148;
            
        ethReverseResolver = ReverseRegistrar(reverseEthRegAddress);
    }
    
    function setTokenImageBaseUrl(string calldata _tokenImageBaseUrl) public onlyOwner {
        tokenImageBaseUrl = _tokenImageBaseUrl;
    }
    
    function setTokenBackgroundImageBaseURL(string calldata _tokenBackgroundImageBaseURL) public onlyOwner {
        tokenBackgroundImageBaseURL = _tokenBackgroundImageBaseURL;
    }
    
    function stringIsASCII(string memory str) public pure returns (bool) {
        return bytes(str).length == str.runeCount();
    }
    
    function getAvatarTextRecord(uint tokenId) public view returns (string memory) {
        bytes32 node = keccak256(abi.encodePacked(controller.tldNode(), bytes32(tokenId)));
        
        TextResolver resolver = TextResolver(ENS(controller.ens()).resolver(node));
        return resolver.text(node, "avatar");
    }
    
    function getNode(uint tokenId) public view returns (bytes32) {
        return keccak256(abi.encodePacked(controller.tldNode(), bytes32(tokenId)));
    }
    
    function tokenImageURL(uint tokenId) public view returns (string memory) {
        return string(abi.encodePacked(
            tokenImageBaseUrl,
            "?id=", tokenId.toString(),
            "&address=", address(this).toHexString(),
            "&chainId=", block.chainid.toString()
            ));
    }
    
    function constructTokenURI(uint tokenId) external view returns (string memory) {
        require(base.exists(tokenId), "Doesn't exist");

        string memory html = tokenHTMLPage(tokenId);
        string memory labelString = controller.hashToLabelString(tokenId);
        
        bool isAscii = stringIsASCII(labelString);
        
        string memory w1 = isAscii ? "" : unicode" ⚠️";
        
        string memory w2 = isAscii ? "" : unicode" ⚠️This name contains non-ASCII characters";
        
        string memory tokenDescription = string.concat(
            "The IP Domain ", labelString, ".ip.", w2
        );
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', string.concat(labelString, ".ip", w1).escapeJSON(), '",'
                                '"description":"', tokenDescription.escapeJSON(), '",'
                                '"image":"', tokenImageURL(tokenId), '",'
                                '"owner":"', base.ownerOf(tokenId).toHexStringChecksumed(), '",'
                                '"animation_url":"data:text/html;charset=utf-8;base64,', Base64.encode(bytes(html)), '",'
                                '"attributes": ', tokenAttributesAsJSON(tokenId),
                                '}'
                            )
                        )
                    )
                )
            );
    }
    
    function tokenAttributesAsJSON(uint tokenId) public view returns (string memory) {
        require(base.exists(tokenId), "Doesn't exist");
        
        uint nameLength = controller.hashToLabelString(tokenId).runeCount();
        uint expirationTimestamp = base.nameExpires(tokenId);
        uint registeredAsOf = base.getLastTransferTimestamp(tokenId);
        
        address owner = base.ownerOf(tokenId);
        string memory ownerString = addressToEthName(owner);

        return string(abi.encodePacked(
            '[',
            '{"display_type": "date", "trait_type": "Expiration Date", "value":', expirationTimestamp.toString(), '},'
            '{"display_type": "date", "trait_type": "Registered As Of", "value":', registeredAsOf.toString(), '},'
            '{"trait_type": "Registered To", "value":"', ownerString.escapeJSON(), '"},'
            '{"display_type": "number", "trait_type":"Length", "value":', nameLength.toString(), '}'
            ']'
        ));
    }
    
    function tokenHTMLPage(uint tokenId) public view returns (string memory) {
        DynamicBufferLib.DynamicBuffer memory HTMLBytes;
        
        string memory label = controller.hashToLabelString(tokenId);
        uint lastTransferTime = base.getLastTransferTimestamp(tokenId);
        address owner = base.ownerOf(tokenId);
        
        string memory bg = bytes(getAvatarTextRecord(tokenId)).length > 0
            ? string.concat("url(", tokenBackgroundImageBaseURL, getAvatarTextRecord(tokenId).escapeHTML(), ")") :
            "linear-gradient(135deg, #00728C 0%, #009CA3 50%, #00A695 100%);";
        
        string memory overlay = bytes(getAvatarTextRecord(tokenId)).length > 0 ? '<div style="width: 100%; height: 100%; position: fixed; top:0; left: 0; background:rgba(0,0,0,.2)"></div>' : "";
        
        string memory ownerString = addressToEthName(owner);
        
        HTMLBytes.append('<!DOCTYPE html><html lang="en">');
        HTMLBytes.append('<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,minimal-ui,viewport-fit=cover,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no"/></head>');
        HTMLBytes.append(abi.encodePacked('<body><div style="background:', bg, ';background-size: cover;color:#fff;left: 50%;top: 50%;transform: translate(-50%, -50%);position: fixed;aspect-ratio: 1 / 1;max-width: 100vmin;max-height: 100vmin;width: 100%; height: 100%;display:flex;flex-direction:column; justify-content: center; align-items:center;box-sizing:border-box"><style>*{box-sizing:border-box;margin:0;padding:0;border:0;-webkit-font-smoothing:antialiased;text-rendering:optimizeLegibility;overflow-wrap:break-word;overflow:hidden; word-break:break-all;user-select: none;text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.2);}'
        ,controller.allFonts(),
        '</style>', overlay, '<div style="width:84%; height:84%; top:0;left:0; z-index: 10000; display:flex; flex-direction: column; justify-content:space-between"><div style="font-size:3.6vw; line-height: 1.3;  letter-spacing: -0.03em;font-family: SatoshiBlack, sans-serif; display: flex; flex-direction:column;">',
        SSTORE2.read(controller.logoSVG()),
        '<div style="margin-top:2vh">Registered to:</div>'
        '<div style="font-family: SatoshiBold;font-size: 3.4vw; line-height: 1.3">',  ownerString.escapeHTML(), '</div>'
        '<div style="font-family: SatoshiBold; font-size: 3.4vw; line-height: 1.3">as of ', timestampToString(lastTransferTime),' UTC</div>'
        '</div>'
        '<div style="font-size:11vw; letter-spacing: -0.03em;line-height:1.2; display: flex; align-items:center; font-family: SatoshiBlack">', label.escapeHTML(), '.ip</div>'
        '</div></div>'));
        
        HTMLBytes.append('</body></html>');

        return string(HTMLBytes.data);
    }
    
    function timestampToString(uint timestamp) internal pure returns (string memory) {
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        
        return string(abi.encodePacked(
          year.toString(), "-",
          zeroPadTwoDigits(month), "-",
          zeroPadTwoDigits(day), ' at ',
            zeroPadTwoDigits(hour), ":",
            zeroPadTwoDigits(minute), ":",
            zeroPadTwoDigits(second)
        ));
    }
    
    function zeroPadTwoDigits(uint number) internal pure returns (string memory) {
        string memory numberString = number.toString();
        
        if (bytes(numberString).length < 2) {
            numberString = string(abi.encodePacked("0", numberString));
        }
        
        return numberString;
    }
}