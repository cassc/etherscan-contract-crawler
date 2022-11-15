// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Bid tree library (sorts from highest amount to lowest amount, then by oldest to newest if they're the same value)
 */
library BidTreeLib {
    /**
      * Represents an active bid
      *
      * @param delivered    - Whether or not the token has been delivered.
      * @param settled      - Whether or not the seller has been paid
      * @param refunded     - Whether or not the bid has been refunded
      */
     struct Bid {
         uint256 amount;
         bool delivered;
         bool settled;
         bool refunded;
         uint48 timestamp;
    }

    struct Node {
        Bid data;
        address parent;
        address left;
        address right;
        bool red;
    }

    struct BidTree {
        address root;
        uint16 size;
        mapping(address => Node) nodes;
    }

    address private constant EMPTY = address(0);

    function first(BidTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }
    function last(BidTree storage self) internal view returns (address _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }
    function next(BidTree storage self, address target) internal view returns (address cursor) {
        require(target != EMPTY);
        if (self.nodes[target].right != EMPTY) {
            cursor = bidTreeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function prev(BidTree storage self, address target) internal view returns (address cursor) {
        require(target != EMPTY);
        if (self.nodes[target].left != EMPTY) {
            cursor = bidTreeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }
    function exists(BidTree storage self, address key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }
    function isEmpty(address key) internal pure returns (bool) {
        return key == EMPTY;
    }
    function getEmpty() internal pure returns (address) {
        return EMPTY;
    }
    function getBid(BidTree storage self, address key) internal view returns (Bid storage) {
        require(exists(self, key));
        return(self.nodes[key].data);
    }

    function insert(BidTree storage self, address key, uint256 amount, uint48 timestamp) internal {
        require(key != EMPTY);
        require(!exists(self, key));
        address cursor = EMPTY;
        address probe = self.root;
        Bid storage cursorData;
        while (probe != EMPTY) {
            cursor = probe;
            cursorData = self.nodes[cursor].data;
            if (amount > cursorData.amount || (amount == cursorData.amount && timestamp < cursorData.timestamp)) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({data: Bid({amount: amount, delivered: false, settled: false, refunded: false, timestamp: timestamp}), parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else {
          cursorData = self.nodes[cursor].data;
          if (amount > cursorData.amount || (amount == cursorData.amount && timestamp < cursorData.timestamp)) {
            self.nodes[cursor].left = key;
          } else {
            self.nodes[cursor].right = key;
          }
        }
        insertFixup(self, key);
        self.size += 1;
    }
    function remove(BidTree storage self, address key) internal {
        require(key != EMPTY);
        require(exists(self, key));
        address probe;
        address cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        address yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
        self.size -= 1;
    }

    function bidTreeMinimum(BidTree storage self, address key) private view returns (address) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }
    function bidTreeMaximum(BidTree storage self, address key) private view returns (address) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(BidTree storage self, address key) private {
        address cursor = self.nodes[key].right;
        address keyParent = self.nodes[key].parent;
        address cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }
    function rotateRight(BidTree storage self, address key) private {
        address cursor = self.nodes[key].left;
        address keyParent = self.nodes[key].parent;
        address cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(BidTree storage self, address key) private {
        address cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            address keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                      key = keyParent;
                      rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                      key = keyParent;
                      rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(BidTree storage self, address a, address b) private {
        address bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }
    function removeFixup(BidTree storage self, address key) private {
        address cursor;
        while (key != self.root && !self.nodes[key].red) {
            address keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black BidTree Library
// ----------------------------------------------------------------------------