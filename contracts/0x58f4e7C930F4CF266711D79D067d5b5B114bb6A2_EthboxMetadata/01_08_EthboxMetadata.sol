// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./strings.sol";
import "./base64.sol";
import "./EthboxStructs.sol";

abstract contract ReverseRegistrar {
    function node(address addr) public pure virtual returns (bytes32);
}

abstract contract ENS {
    function resolver(bytes32 node) public view virtual returns (address);
}

abstract contract Resolver {
    function name(bytes32 node) public view virtual returns (string memory);
}

contract EthboxMetadata is Ownable {
    using Address for address;
    using Strings for uint256;
    using strings for *;

    ENS ens;
    ReverseRegistrar reverseRegistrar;

    string private desc;
    string private externalUrl;
    string private messageInsert;
    string private ethboxInsert;
    string private emptyInsert;

    constructor() {
        ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        // reverseRegistrar = ReverseRegistrar(0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c); //rinkeby
        reverseRegistrar = ReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148);//mainnet
        externalUrl = "https://ethbox.nxc.io/address/";
        desc = "Ethbox is a fully on-chain Ethereum messaging protocol that enables any wallet to bid ETH to send messages to another wallet.";
        messageInsert = '<g id="message-${_INDEX}" style="display:${_VISIBILITY}" onclick="cycleMessage()"><foreignObject x="5%" y="5%" width="97.1%" height="14.2%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:0.9em">to  : ${_TO}</div></foreignObject><foreignObject x="5%" y="10%" width="97.1%" height="14.2%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:0.9em">from: ${_FROM} </div></foreignObject><foreignObject x="5%" y="15%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:1.5em"> ${_MESSAGE} </div></foreignObject><foreignObject x="5%" y="85%" width="90%" height="80%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:1.8em;text-align:left"> Bid: ${_VALUE} ETH </div></foreignObject><foreignObject x="82%" y="85%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:1.5em;text-align:left">(${_POSITION})</div></foreignObject></g>';
        emptyInsert = '<g style="display:visible"><foreignObject x="7.5%" y="45%" width="97.1%" height="14.2%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:white;font-family:monospace;font-size:0.9em"> ${_TO}</div></foreignObject><foreignObject x="7.5%" y="10%" width="97.1%" height="90%"><div class = "plain-text" xmlns="http://www.w3.org/1999/xhtml" style="color:#00ff40;font-family:monospace;font-size:1.5em"> Empty Ethbox</div></foreignObject></g>';
        ethboxInsert = '<svg id= "wrapper" width="350px" height="350px" viewbox="0 0 100% 100%" xmlns="http://www.w3.org/2000/svg" xmlns:xlink= "http://www.w3.org/1999/xlink"><rect width="100%" height="100%" fill="#0d140c" /><text x="5%" y="95%" font-size="0.8em" fill="#00ff40" font-family="monospace"> Click or tap to cycle messages </text>${_MESSAGES}<script>var current_message = 0;var messages = document.querySelectorAll(\'[id^="message-"]\');document.getElementById("wrapper").setAttribute("width", "100%");document.getElementById("wrapper").setAttribute("height", "100%");function cycleMessage() {document.getElementById("message-" + current_message).style.display ="none";current_message = (current_message + 1) % messages.length;document.getElementById("message-" + current_message).style.display ="block";};</script></svg>';
    }

    //////////////////////////////////////
    //////////////////////////////////////
    // Display and metadata functions //
    //todo : embed variables

    function setDesc(string memory _desc) external onlyOwner {
        desc = _desc;
    }

    function setExternalUrl(string memory _externalUrl) external onlyOwner {
        externalUrl = _externalUrl;
    }

    function setMessageInsert(string memory _messageInsert) external onlyOwner {
        messageInsert = _messageInsert;
    }

    function setEthboxInsert(string memory _ethboxInsert) external onlyOwner {
        ethboxInsert = _ethboxInsert;
    }

    function setEmptyInsert(string memory _emtpyInsert) external onlyOwner {
        emptyInsert = _emtpyInsert;
    }

    function valueToEthString(uint256 _value)
        public
        pure
        returns (string memory)
    {
        if (_value == 0) return "0";
        strings.slice memory eRep = Strings.toString(_value).toSlice();
        strings.slice memory zero = "0".toSlice();
        uint256 len = eRep.len();
        if (len > 18) {
            // more then 1eth, add a dot and remove trailing 0's
            uint256 roundEth = _value / 1 ether;
            strings.slice memory round = Strings.toString(roundEth).toSlice();
            eRep.split(round);
            while (eRep.endsWith(zero)) {
                eRep.until(zero);
            }
            return
                string(
                    abi.encodePacked(round.toString(), ".", eRep.toString())
                );
        } else {
            uint256 diff = 18 - len;
            strings.slice memory padding = "0.".toSlice();
            for (diff; diff != 0; diff--) {
                padding = padding.concat(zero).toSlice();
            }
            while (eRep.endsWith(zero)) {
                eRep.until(zero);
            }
            return
                string(abi.encodePacked(padding.toString(), eRep.toString()));
        }
    }

    function addressToENSCertain(address _address)
        public
        view
        returns (string memory)
    {
        bytes32 node = reverseRegistrar.node(_address);
        address resolverAddress = ens.resolver(node);
        if (resolverAddress == address(0))
            return Strings.toHexString(uint160(_address), 20);
        Resolver resolver = Resolver(resolverAddress);

        return resolver.name(node);
    }

    function addressToENS(address _address)
        public
        view
        returns (string memory)
    {
        bytes32 node = reverseRegistrar.node(_address);
        address resolverAddress = ens.resolver(node);
        if (resolverAddress == address(0))
            return Strings.toHexString(uint160(_address), 20);
        Resolver resolver = Resolver(resolverAddress);
        string memory name = resolver.name(node);
        return 
            string(
                abi.encodePacked(
                    "(maybe) ",
                    name
                ));
    }

    function buildEthboxImage(
        address owner,
        EthboxStructs.UnpackedMessage[] memory messages
    ) public view returns (string memory) {
        string memory svg = buildSVG(owner, messages, messages.length);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svg))
                )
            );
    }

    function buildEthboxHtml(
        address owner,
        EthboxStructs.UnpackedMessage[] memory messages
    ) public view returns (string memory) {
        string memory svg = buildSVG(owner, messages, messages.length);
        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    "<html><body>",
                                    svg,
                                    "</body></html>"
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildSingleMessageSVG(EthboxStructs.MessageInfo memory _display)
        private
        view
        returns (string memory)
    {
        strings.slice memory sliceMessage = messageInsert.toSlice();

        string memory output = string(
            abi.encodePacked(
                sliceMessage.split("${_INDEX}".toSlice()).toString(),
                Strings.toString(_display.index),
                sliceMessage.split("${_VISIBILITY}".toSlice()).toString(),
                _display.visibility,
                sliceMessage.split("${_TO}".toSlice()).toString(),
                addressToENS(_display.to),
                sliceMessage.split("${_FROM}".toSlice()).toString(),
                addressToENS(_display.message.from),
                sliceMessage.split("${_MESSAGE}".toSlice()).toString()
            )
        );

        output = string(
            abi.encodePacked(
                output,
                _display.message.message,
                sliceMessage.split("${_VALUE}".toSlice()).toString(),
                valueToEthString(_display.message.originalValue),
                sliceMessage.split("${_POSITION}".toSlice()).toString(),
                Strings.toString(_display.index + 1),
                "/",
                Strings.toString(_display.maxSize),
                sliceMessage.toString()
            )
        );

        return output;
    }

    function buildEmptyEthboxSVG(address _to)
        private
        view
        returns (string memory)
    {
        strings.slice memory sliceMessage = emptyInsert.toSlice();

        string memory output = string(
            abi.encodePacked(
                sliceMessage.split("${_TO}".toSlice()).toString(),
                addressToENS(_to),
                sliceMessage.toString()
            )
        );

        return output;
    }

    function buildSVG(
        address _to,
        EthboxStructs.UnpackedMessage[] memory _messages,
        uint256 _maxSize
    ) private view returns (string memory) {
        strings.slice memory sliceEthbox = ethboxInsert.toSlice();
        string memory output = sliceEthbox
            .split("${_MESSAGES}".toSlice())
            .toString();
        string memory visibility = "visible";
        if (_messages.length == 0) {
            output = string(abi.encodePacked(output, buildEmptyEthboxSVG(_to)));
        } else {
            for (uint256 i = 0; i < _messages.length; i++) {
                if (i == 1) {
                    visibility = "none";
                }
                EthboxStructs.MessageInfo memory display = EthboxStructs
                    .MessageInfo(_to, visibility, _messages[i], i, _maxSize);
                output = string(
                    abi.encodePacked(output, buildSingleMessageSVG(display))
                );
            }
        }

        return string(abi.encodePacked(output, sliceEthbox.toString()));
    }

    function buildMetadata(
        address owner,
        EthboxStructs.UnpackedMessage[] memory messages,
        uint256 ethboxSize,
        uint256 ethboxDrip
    ) public view returns (string memory) {
        uint256 currentSize = messages.length;
        string memory output = string(
            abi.encodePacked(
                '{"name":"',
                addressToENS(owner),
                '", "description":"',
                desc,
                '", "external_url":"',
                externalUrl,
                addressToENSCertain(owner),
                '", "attributes": '
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                '[{ "trait_type": "Max Capacity", "value": ',
                Strings.toString(ethboxSize),
                '},{ "trait_type": "Message Count", "value": ',
                Strings.toString(currentSize),
                '},{ "trait_type": "Drip Time", "value": ',
                Strings.toString(ethboxDrip),
                "}]"
            )
        );

        output = string(abi.encodePacked(output, attributes, ', "image": "'));
        string memory svg = buildSVG(owner, messages, currentSize);
        output = string(
            abi.encodePacked(
                output,
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(svg)),
                '", "animation_url": "data:text/html;base64,',
                Base64.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                "<html><body>",
                                svg,
                                "</body></html>"
                            )
                        )
                    )
                ),
                '"}'
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(output))
                )
            );
    }
}