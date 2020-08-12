// chpl version 1.23.0 pre-release (a25ae3153)
//
// Proof of concept for C++ CRTP in Chapel
//
// Note: Do not use. Chapel does not support multiple inheritance, so this
// technique is not that useful. Prefer interfaces for constrained generics.

class Add {
    // For base skill.
    type T;

    proc add(other: T): owned T {
        return (this :T(T)).addImpl(other);
    }

    proc type geometryId(): string {
        return T.geometryIdImpl();
    }
}

class AddMul: Add {
    // For aggregate skills.
    proc init(type T) {
        super.init(T);
    }

    proc mul(other: T): owned T {
        return (this :T(T)).mulImpl(other);
    }
}

class Point: AddMul {
    var x: int;
    var y: int;

    proc init(x: int, y: int) {
        super.init(T = this.type);
        this.x = x;
        this.y = y;
    }

    // Omitting an Impl function will generate a reasonable compiler error.

    proc addImpl(other: T): owned T {
        return new owned Point(
            this.x + other.x,
            this.y + other.y
        );
    }

    proc mulImpl(other: T): owned T {
        return new owned Point(
            this.x * other.x,
            this.y * other.y
        );
    }

    proc type geometryIdImpl(): string {
        return "Euclidean";
    }
}

proc main() {
    var p1 = new owned Point(2, 3);
    var p2 = new owned Point(4, 5);

    writeln(p1.add(p2)); // Point(6, 8)
    writeln(p1.mul(p2)); // Point(8, 15)

    // Using a type method is awkward.
    var geo = Point(Point).geometryId();
    writeln(geo);
}
