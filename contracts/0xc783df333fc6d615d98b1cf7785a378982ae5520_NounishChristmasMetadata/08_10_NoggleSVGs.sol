// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library NoggleSVGs {
    function basic() internal pure returns (string memory) {
        return '<rect x="6" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="8" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="16" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="7" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="9" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="9" width="2" height="1" class="noggles"/>'
        '<rect x="9" y="9" width="2" height="1" class="noggles"/>'
        '<rect x="15" y="7" width="1" height="2" fill="black"/>'
        '<rect x="10" y="7" width="1" height="2" fill="black"/>'
        '<rect x="14" y="7" width="1" height="2" fill="white"/>' '<rect x="9" y="7" width="1" height="2" fill="white"/>';
    }

    function cool() internal pure returns (string memory) {
        return '<rect x="6" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="8" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="16" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="4" class="noggles"/>'
        '<rect x="7" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="9" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="6" width="2" height="1" class="noggles"/>'
        '<rect x="14" y="7" width="1" height="3" class="noggles"/>'
        '<rect x="9" y="7" width="1" height="3" class="noggles"/>'
        '<rect x="10" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="15" y="8" width="1" height="2" class="noggles"/>'
        '<rect x="15" y="7" width="1" height="1" fill="white"/>'
        '<rect x="10" y="7" width="1" height="1" fill="white"/>';
    }

    function large() internal pure returns (string memory) {
        return '<rect x="3" y="8" width="1" height="3" class="noggles"/>'
        '<rect x="4" y="8" width="2" height="1" class="noggles"/>'
        '<rect x="6" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="7" y="11" width="4" height="1" class="noggles"/>'
        '<rect x="7" y="6" width="4" height="1" class="noggles"/>'
        '<rect x="11" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="12" y="8" width="1" height="1" class="noggles"/>'
        '<rect x="13" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="18" y="6" width="1" height="6" class="noggles"/>'
        '<rect x="14" y="6" width="4" height="1" class="noggles"/>'
        '<rect x="14" y="11" width="4" height="1" class="noggles"/>'
        '<rect x="16" y="7" width="2" height="4" fill="black"/>' '<rect x="9" y="7" width="2" height="4" fill="black"/>'
        '<rect x="14" y="7" width="2" height="4" fill="white"/>' '<rect x="7" y="7" width="2" height="4" fill="white"/>';
    }
}